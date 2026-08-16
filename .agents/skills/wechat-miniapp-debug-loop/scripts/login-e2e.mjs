#!/usr/bin/env node
import { mkdir, readFile, stat, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { connectDevTools, DEFAULT_AUTO_PORT, DEFAULT_CLI, DEFAULT_IDE_PORT, DEFAULT_PROJECT, parseArgs } from './devtools-connect.mjs';
import {
  attachRuntimeEvents,
  countApplicationErrors,
  installRuntimeCapture,
  readRuntimeCapture,
  sanitize
} from './collect-runtime.mjs';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const delay = (milliseconds) => new Promise((resolvePromise) => setTimeout(resolvePromise, milliseconds));
const TOKEN_KEY = 'security.siam.token';
const OPENID_KEY = 'security.siam.openid';
const PHONE_KEY = 'security.siam.phone';
const step = (name) => console.error(`[login-e2e] ${name}`);

async function currentPage(miniProgram, expectedPath, timeout = 10000) {
  const deadline = Date.now() + timeout;
  let page = null;
  while (Date.now() < deadline) {
    page = await miniProgram.currentPage();
    if (!expectedPath || page?.path === expectedPath) return page;
    await delay(250);
  }
  throw new Error(`Expected page ${expectedPath}, current ${page?.path || 'empty'}`);
}

async function pageByRoute(miniProgram, expectedPath) {
  const deadline = Date.now() + 10000;
  let observed = '';
  while (Date.now() < deadline) {
    const page = await miniProgram.currentPage();
    observed = page?.path || '';
    if (observed === expectedPath) return page;
    await delay(250);
  }
  throw new Error(`Automator current page missing for ${expectedPath}; observed=${observed || 'empty'}`);
}

async function findElement(page, selectors) {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    for (const selector of selectors) {
      const element = await page.$(selector);
      if (element) return { element, selector };
    }
    await delay(250);
  }
  throw new Error(`Element not found: ${selectors.join(', ')}`);
}

async function readText(page, selector) {
  const element = await page.$(selector);
  return element ? String(await element.text()) : '';
}

async function backendErrorsSince(path, offset) {
  if (!path || !existsSync(path)) return { checked: false, count: null };
  const content = await readFile(path, 'utf8');
  const added = content.slice(offset);
  const matches = added.match(/(^|\n).*\bERROR\b.*$/gim) || [];
  return { checked: true, count: matches.length, samples: matches.slice(0, 5).map((line) => sanitize(line)) };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const phone = process.env.WECHAT_E2E_PHONE;
  const smsCode = process.env.WECHAT_E2E_SMS_CODE;

  const evidenceDir = resolve(args.evidence || process.env.WECHAT_EVIDENCE_DIR || tmpdir(),
    `wechat-login-e2e-${new Date().toISOString().replace(/[:.]/g, '-')}`);
  await mkdir(evidenceDir, { recursive: true });

  const backendLog = args['backend-log'] || process.env.WECHAT_BACKEND_LOG || '';
  const backendOffset = backendLog && existsSync(backendLog) ? (await stat(backendLog)).size : 0;
  const state = {
    port9420: false,
    automator: false,
    elementQuery: false,
    elementTap: false,
    loginButton: false,
    wxLogin: false,
    code2Session: false,
    token: false,
    storage: false,
    me: false,
    uiLoggedIn: false,
    reloadPersisted: false,
    consoleRedErrors: null,
    backendErrors: null,
    evidenceDir
  };

  let miniProgram;
  try {
    step('connect');
    const connected = await connectDevTools({
      projectPath: args.project ? resolve(args.project) : DEFAULT_PROJECT,
      cliPath: args.cli || process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
      autoPort: Number(args.port || DEFAULT_AUTO_PORT),
      idePort: Number(args['ide-port'] || DEFAULT_IDE_PORT),
      retries: Number(args.retries || 3)
    });
    miniProgram = connected.miniProgram;
    state.port9420 = connected.autoPort === 9420;
    state.automator = true;
    step('connected');
    await currentPage(miniProgram);
    const runtimeEvents = attachRuntimeEvents(miniProgram);

    await miniProgram.callWxMethod('removeStorageSync', TOKEN_KEY);
    await miniProgram.callWxMethod('removeStorageSync', OPENID_KEY);
    await miniProgram.callWxMethod('removeStorageSync', PHONE_KEY);

    step('switch-to-mine');
    await miniProgram.switchTab('/pages/mine/index/index');
    let page = await currentPage(miniProgram, 'pages/mine/index/index');
    step('install-capture');
    await installRuntimeCapture(miniProgram);

    step('tap-profile');
    const profileEntry = await findElement(page, ['#login-entry-button', '.profile-card']);
    state.elementQuery = true;
    await profileEntry.element.tap();
    state.elementTap = true;
    state.loginButton = true;
    page = await pageByRoute(miniProgram, 'pages/internal/login/choose/choose');

    step('tap-verification-login');
    const verificationEntry = await findElement(page, ['#verification-login-button', '.verification-code']);
    await verificationEntry.element.tap();
    page = await pageByRoute(miniProgram, 'pages/internal/login/code/code');
    step('login-page-ready');

    if (!phone || !smsCode) {
      const runtime = await readRuntimeCapture(miniProgram);
      state.wxLogin = Boolean(runtime.logins?.some((item) => item.ok && item.hasCode));
      const applicationErrors = countApplicationErrors(runtimeEvents.consoleRecords, runtimeEvents.exceptions);
      state.consoleRedErrors = applicationErrors.consoleErrors.length + applicationErrors.exceptions.length;
      const backend = await backendErrorsSince(backendLog, backendOffset);
      state.backendErrors = backend.count;
      await miniProgram.screenshot({ path: resolve(evidenceDir, 'login-input-required.png') });
      await writeFile(resolve(evidenceDir, 'login-e2e.json'), JSON.stringify(sanitize({
        state,
        route: page.path,
        runtime: { logins: runtime.logins, requestCount: runtime.requests?.length || 0 },
        console: applicationErrors,
        backend,
        blocker: 'A real phone/SMS credential step is required; no value is persisted by this Skill.'
      }), null, 2), 'utf8');
      console.log(JSON.stringify({
        ...state,
        loginAutomationPass: false,
        blocker: state.wxLogin ? 'REAL_PHONE_OR_SMS_CODE_REQUIRED' : 'WX_LOGIN_FAILED'
      }, null, 2));
      process.exitCode = 1;
      return;
    }

    const phoneInput = await findElement(page, ['#login-phone-input']);
    const codeInput = await findElement(page, ['#login-code-input']);
    await phoneInput.element.input(phone);
    await codeInput.element.input(smsCode);

    const confirm = await findElement(page, ['#login-button', '.confirm-btn', 'van-button']);
    await confirm.element.tap();

    page = await currentPage(miniProgram, 'pages/mine/index/index', 20000);
    await delay(1500);
    const runtime = await readRuntimeCapture(miniProgram);
    const loginRequest = (runtime.requests || []).find((item) => item.request?.url?.includes('/rest/member/verification/login'));
    const meRequest = (runtime.requests || []).find((item) => item.request?.url?.includes('/rest/member/getLoginMemberInfo'));
    state.wxLogin = Boolean(runtime.logins?.some((item) => item.ok && item.hasCode));
    state.code2Session = state.wxLogin
      && Boolean(loginRequest?.response?.statusCode >= 200 && loginRequest?.response?.statusCode < 300)
      && Boolean(loginRequest?.response?.data?.success);
    state.token = Boolean(loginRequest?.response?.data?.data?.token);

    const storedToken = await miniProgram.callWxMethod('getStorageSync', TOKEN_KEY);
    state.storage = Boolean(storedToken);
    state.me = Boolean(meRequest?.response?.statusCode >= 200 && meRequest?.response?.statusCode < 300)
      && Boolean(meRequest?.response?.data?.success);

    const profileText = await readText(page, '.profile-name');
    state.uiLoggedIn = Boolean(profileText && profileText !== '登录 / 注册');
    await miniProgram.screenshot({ path: resolve(evidenceDir, 'logged-in.png') });

    await miniProgram.reLaunch('/pages/mine/index/index');
    page = await currentPage(miniProgram, 'pages/mine/index/index');
    await delay(1500);
    const reloadToken = await miniProgram.callWxMethod('getStorageSync', TOKEN_KEY);
    const reloadText = await readText(page, '.profile-name');
    state.reloadPersisted = Boolean(reloadToken && reloadText && reloadText !== '登录 / 注册');
    await miniProgram.screenshot({ path: resolve(evidenceDir, 'reloaded.png') });

    const applicationErrors = countApplicationErrors(runtimeEvents.consoleRecords, runtimeEvents.exceptions);
    state.consoleRedErrors = applicationErrors.consoleErrors.length + applicationErrors.exceptions.length;
    const backend = await backendErrorsSince(backendLog, backendOffset);
    state.backendErrors = backend.count;

    const evidence = sanitize({
      state,
      route: page.path,
      loginRequest,
      meRequest,
      runtime: { logins: runtime.logins, requestCount: runtime.requests?.length || 0 },
      console: applicationErrors,
      backend
    });
    await writeFile(resolve(evidenceDir, 'login-e2e.json'), JSON.stringify(evidence, null, 2), 'utf8');

    const pass = state.port9420 && state.automator && state.elementQuery && state.elementTap
      && state.loginButton && state.wxLogin && state.code2Session
      && state.token && state.storage && state.me && state.uiLoggedIn && state.reloadPersisted
      && state.consoleRedErrors === 0 && state.backendErrors === 0;
    console.log(JSON.stringify({ ...state, loginAutomationPass: pass }, null, 2));
    if (!pass) process.exitCode = 1;
  } finally {
    if (miniProgram) {
      try { await miniProgram.disconnect(); } catch {}
    }
  }
}

main().catch((error) => {
  console.error(JSON.stringify({ loginAutomationPass: false, error: sanitize(error.message) }, null, 2));
  process.exit(1);
});
