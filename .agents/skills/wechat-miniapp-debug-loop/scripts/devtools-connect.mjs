#!/usr/bin/env node
import { execFile } from 'node:child_process';
import { existsSync } from 'node:fs';
import net from 'node:net';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { connectAutomator, launchAutomator } from './automator-client.mjs';

const execFileAsync = promisify(execFile);
const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, '../../../..');

export const DEFAULT_PROJECT = resolve(repoRoot, 'uniapp-siam-user/unpackage/dist/dev/mp-weixin');
export const DEFAULT_CLI = existsSync('C:/codex-wechat-devtools/cli.bat')
  ? 'C:/codex-wechat-devtools/cli.bat'
  : 'C:/Program Files (x86)/Tencent/微信web开发者工具/cli.bat';
export const DEFAULT_AUTO_PORT = 9420;
export const DEFAULT_IDE_PORT = 9421;

export function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith('--')) continue;
    const key = argv[index].slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith('--')) result[key] = true;
    else {
      result[key] = value;
      index += 1;
    }
  }
  return result;
}

const delay = (milliseconds) => new Promise((resolvePromise) => setTimeout(resolvePromise, milliseconds));
const withTimeout = (promise, label, milliseconds = 10000) => Promise.race([
  promise,
  new Promise((_, reject) => setTimeout(() => reject(new Error(`${label} timeout after ${milliseconds}ms`)), milliseconds))
]);

export async function waitForCurrentPage(miniProgram, timeout = 60000) {
  const deadline = Date.now() + timeout;
  let lastError = null;
  let stack = [];
  while (Date.now() < deadline) {
    try {
      await miniProgram.send('Tool.getInfo');
      stack = await miniProgram.pageStack();
      const page = await miniProgram.currentPage();
      if (page?.path) return { page, stack };
    } catch (error) {
      lastError = error;
    }
    await delay(500);
  }
  const routes = stack.map((page) => page.path).filter(Boolean).join(', ') || 'empty';
  throw new Error(`Automator page metadata not ready after ${timeout}ms; pageStack=${routes}; last=${lastError?.message || 'empty currentPage'}`);
}

export function isPortListening(port) {
  return new Promise((resolvePromise) => {
    const socket = net.createConnection({ host: '127.0.0.1', port });
    socket.once('connect', () => {
      socket.destroy();
      resolvePromise(true);
    });
    socket.once('error', () => resolvePromise(false));
    socket.setTimeout(1500, () => {
      socket.destroy();
      resolvePromise(false);
    });
  });
}

async function runCli(cliPath, args, timeout = 30000) {
  try {
    const useShell = process.platform === 'win32' && /\.(bat|cmd)$/i.test(cliPath);
    const executable = useShell ? 'powershell.exe' : cliPath;
    const quotePowerShell = (value) => `'${String(value).replaceAll("'", "''")}'`;
    const effectiveArgs = useShell
      ? [
          '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command',
          `& ${quotePowerShell(cliPath)} ${args.map(quotePowerShell).join(' ')}`
        ]
      : args;
    const { stdout = '', stderr = '' } = await execFileAsync(executable, effectiveArgs, {
      timeout,
      windowsHide: true,
      maxBuffer: 1024 * 1024
    });
    return { ok: true, stdout, stderr };
  } catch (error) {
    return {
      ok: false,
      stdout: String(error.stdout || ''),
      stderr: String(error.stderr || error.message || '')
    };
  }
}

async function protocolConnect(port) {
  const miniProgram = await withTimeout(connectAutomator(`ws://127.0.0.1:${port}`), 'Automator WebSocket connect');
  return { miniProgram };
}

export async function connectDevToolsTransport({
  projectPath = DEFAULT_PROJECT,
  cliPath = process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
  autoPort = DEFAULT_AUTO_PORT,
  retries = 3
} = {}) {
  if (!existsSync(projectPath)) throw new Error(`Generated mini-program project not found: ${projectPath}`);
  if (!existsSync(resolve(projectPath, 'project.config.json'))) throw new Error('project.config.json is missing');
  if (!existsSync(cliPath)) throw new Error(`WeChat Developer Tools CLI not found: ${cliPath}`);

  let lastError = null;
  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      if (await isPortListening(autoPort)) {
        const connected = await protocolConnect(autoPort);
        return { ...connected, cliPath, projectPath, autoPort, attempt, reused: true };
      }
      const miniProgram = await launchAutomator({
        cliPath,
        projectPath,
        port: autoPort,
        trustProject: true,
        timeout: 30000,
        args: ['--lang', 'zh']
      });
      return { miniProgram, cliPath, projectPath, autoPort, attempt: attempt + 1, reused: false };
    } catch (error) {
      lastError = error;
      if (attempt < retries) {
        await runCli(cliPath, ['quit'], 15000);
        await delay(2500);
      }
    }
  }
  throw new Error(`Automator transport failed after ${retries + 1} rounds: ${lastError?.message || 'unknown error'}`);
}

export async function connectDevTools({
  projectPath = DEFAULT_PROJECT,
  cliPath = process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
  autoPort = DEFAULT_AUTO_PORT,
  idePort = DEFAULT_IDE_PORT,
  retries = 3
} = {}) {
  const connected = await connectDevToolsTransport({ projectPath, cliPath, autoPort, retries });
  try {
    let ready;
    try {
      ready = await waitForCurrentPage(connected.miniProgram, 45000);
    } catch (initialError) {
      const stack = await connected.miniProgram.pageStack().catch(() => []);
      if (stack.length) throw initialError;
      await connected.miniProgram.callWxMethod('reLaunch', { url: '/pages/index/index' });
      ready = await waitForCurrentPage(connected.miniProgram, 30000);
    }
    return { ...connected, page: ready.page, pageStack: ready.stack };
  } catch (error) {
    connected.miniProgram.disconnect();
    throw error;
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  let result;
  try {
    result = await connectDevTools({
      projectPath: args.project ? resolve(args.project) : DEFAULT_PROJECT,
      cliPath: args.cli || process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
      autoPort: Number(args.port || DEFAULT_AUTO_PORT),
      idePort: Number(args['ide-port'] || DEFAULT_IDE_PORT),
      retries: Number(args.retries || 3)
    });
    console.log(JSON.stringify({
      portListening: true,
      protocolConnected: true,
      currentPage: result.page.path,
      attempt: result.attempt,
      reused: result.reused
    }, null, 2));
  } finally {
    if (result?.miniProgram) result.miniProgram.disconnect();
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(JSON.stringify({ portListening: false, protocolConnected: false, error: error.message }, null, 2));
    process.exit(1);
  });
}
