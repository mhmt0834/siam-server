import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join } from 'node:path';

const require = createRequire(import.meta.url);
const Launcher = require('miniprogram-automator/out/Launcher').default;

export async function connectAutomator(wsEndpoint) {
  const launcher = new Launcher();
  // Developer Tools 2.02.2607271 returns Tool.getInfo.version but omits the
  // legacy SDKVersion field expected by miniprogram-automator 0.12.1.
  // connectTool uses the package's real transport and public MiniProgram API;
  // skipping only the stale client-side version-field check keeps UI E2E real.
  return launcher.connectTool({ wsEndpoint });
}

export async function launchAutomator(options) {
  const {
    cliPath,
    projectPath,
    port = 9420,
    timeout = 30000,
    trustProject = true,
    args = []
  } = options;
  const launcher = new Launcher();
  const cliArgs = [
    'auto', '--project', projectPath, '--auto-port', String(port),
    ...(trustProject ? ['--trust-project'] : []),
    ...args
  ];
  let spawnError = null;
  let cliOutput = '';
  const isBatch = process.platform === 'win32' && /\.(bat|cmd)$/i.test(cliPath);
  const cliDir = dirname(cliPath);
  const electronPath = join(cliDir, '微信开发者工具.exe');
  const cliEntry = join(cliDir, 'resources/app.asar.unpacked/js/common/cli/index.js');
  const legacyNode = join(cliDir, 'node-18.exe');
  const legacyCliEntry = join(cliDir, 'code/package.nw/js/common/cli/index.js');
  const bootstrap = "const e=process.argv[1],a=process.argv.slice(2).filter(function(x){return x!=='--electron'});if(!process.env.cwd)process.env.cwd=process.cwd();process.argv=[process.execPath,'--ms-enable-electron-run-as-node',e,'--electron'].concat(a);require(e)";
  const child = isBatch && existsSync(legacyNode) && existsSync(legacyCliEntry)
    ? spawn(legacyNode, [legacyCliEntry, ...cliArgs], {
        cwd: cliDir,
        env: { ...process.env, cwd: process.cwd() },
        stdio: ['ignore', 'pipe', 'pipe'],
        windowsHide: true
      })
    : isBatch
    ? spawn(electronPath, ['-e', bootstrap, cliEntry, ...cliArgs], {
        cwd: cliDir,
        env: { ...process.env, ELECTRON_RUN_AS_NODE: '1', ELECTRON: '', cwd: process.cwd() },
        stdio: ['ignore', 'pipe', 'pipe'],
        windowsHide: true
      })
    : spawn(cliPath, cliArgs, {
        stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true
      });
  child.once('error', (error) => { spawnError = error; });
  const capture = (chunk) => { cliOutput = `${cliOutput}${chunk}`.slice(-2000); };
  child.stdout.on('data', capture);
  child.stderr.on('data', capture);

  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (spawnError) throw spawnError;
    try {
      // Use the installed package's actual transport/API while keeping the CLI
      // process and connection attempts concurrent, as Launcher.launch does.
      return await launcher.connectTool({ wsEndpoint: `ws://127.0.0.1:${port}` });
    } catch {
      await new Promise((resolvePromise) => setTimeout(resolvePromise, 250));
    }
  }
  if (!child.killed) child.kill();
  const detail = cliOutput.trim().replace(/\s+/g, ' ').slice(-500);
  throw new Error(`Failed connecting to Developer Tools automation port ${port} within ${timeout}ms${detail ? `: ${detail}` : ''}`);
}
