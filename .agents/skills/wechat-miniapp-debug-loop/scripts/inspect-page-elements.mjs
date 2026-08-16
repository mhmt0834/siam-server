#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  connectDevToolsTransport,
  DEFAULT_AUTO_PORT,
  DEFAULT_CLI,
  DEFAULT_IDE_PORT,
  DEFAULT_PROJECT,
  parseArgs,
  waitForCurrentPage
} from './devtools-connect.mjs';

const timeout = (promise, name, milliseconds = 8000) => Promise.race([
  promise,
  new Promise((_, reject) => setTimeout(() => reject(new Error(`${name} timeout after ${milliseconds}ms`)), milliseconds))
]);

async function inspectSelector(page, selector) {
  try {
    const elements = await timeout(page.$$(selector), `query ${selector}`);
    const nodes = [];
    for (const element of elements.slice(0, 10)) {
      nodes.push({
        tagName: element.tagName,
        id: await timeout(element.attribute('id'), `${selector} id`).catch(() => null),
        className: await timeout(element.attribute('class'), `${selector} class`).catch(() => null),
        text: await timeout(element.text(), `${selector} text`).catch(() => null),
        nodeId: Boolean(element.nodeId)
      });
    }
    return { selector, ok: true, count: elements.length, nodes };
  } catch (error) {
    return { selector, ok: false, count: null, error: error.message };
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  console.error('[inspect] connect');
  const connected = await connectDevToolsTransport({
    projectPath: args.project ? resolve(args.project) : DEFAULT_PROJECT,
    cliPath: args.cli || process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
    autoPort: Number(args.port || DEFAULT_AUTO_PORT),
    idePort: Number(args['ide-port'] || DEFAULT_IDE_PORT),
    retries: Number(args.retries || 1)
  });

  try {
    console.error('[inspect] currentPage/pageStack readiness');
    let bootstrapNavigation = false;
    let ready;
    try {
      ready = await waitForCurrentPage(connected.miniProgram, 45000);
    } catch (initialError) {
      const initialStack = await connected.miniProgram.pageStack().catch(() => []);
      if (initialStack.length) throw initialError;
      console.error('[inspect] empty page stack; normal reLaunch bootstrap');
      await connected.miniProgram.callWxMethod('reLaunch', { url: '/pages/index/index' });
      bootstrapNavigation = true;
      try {
        ready = await waitForCurrentPage(connected.miniProgram, 15000);
      } catch (reLaunchError) {
        console.error('[inspect] service-layer reLaunch did not register page; native goHome');
        await connected.miniProgram.native().goHome();
        ready = await waitForCurrentPage(connected.miniProgram, 15000).catch(() => {
          throw reLaunchError;
        });
      }
    }
    const { page, stack } = ready;
    console.error('[inspect] pageData');
    const pageData = await timeout(page.data(), 'pageData').catch((error) => ({ error: error.message }));
    const selectors = args.selectors
      ? String(args.selectors).split(',').map((item) => item.trim()).filter(Boolean)
      : ['#login-entry-button', '#verification-login-button', '#login-phone-input', '#login-code-input', '#login-button', '.profile-card', '.verification-code', '.confirm-btn', 'button', 'van-button'];
    const inspections = [];
    for (const selector of selectors) {
      console.error(`[inspect] ${selector}`);
      inspections.push(await inspectSelector(page, selector));
    }

    const packagePath = resolve(dirname(fileURLToPath(import.meta.url)), 'node_modules/miniprogram-automator/package.json');
    const automatorPackage = JSON.parse(await readFile(packagePath, 'utf8'));
    const report = {
      automatorVersion: automatorPackage.version,
      bootstrapNavigation,
      route: page.path,
      query: page.query,
      pageLoaded: Boolean(page.path && pageData && !pageData.error),
      pageDataError: pageData?.error || null,
      pageStack: stack.map((item) => ({ path: item.path, query: item.query })),
      expectedLoginEntry: page.path === 'pages/mine/index/index'
        || page.path === 'pages/internal/login/choose/choose'
        || page.path === 'pages/internal/login/code/code',
      inspections
    };
    const output = JSON.stringify(report, null, 2);
    console.log(output);
  } finally {
    connected.miniProgram.disconnect();
  }
}

main().catch((error) => {
  console.error(JSON.stringify({ pass: false, error: error.message }, null, 2));
  process.exit(1);
});
