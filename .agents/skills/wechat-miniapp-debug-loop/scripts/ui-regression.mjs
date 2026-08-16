#!/usr/bin/env node
import { resolve } from 'node:path';
import { connectDevTools, DEFAULT_AUTO_PORT, DEFAULT_CLI, DEFAULT_IDE_PORT, DEFAULT_PROJECT, parseArgs } from './devtools-connect.mjs';

const routes = [
  '/pages/index/index',
  '/pages/menu/index/index',
  '/pages/order/index/index',
  '/pages/mine/index/index'
];

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const connected = await connectDevTools({
    projectPath: args.project ? resolve(args.project) : DEFAULT_PROJECT,
    cliPath: args.cli || process.env.WECHAT_DEVTOOLS_CLI || DEFAULT_CLI,
    autoPort: Number(args.port || DEFAULT_AUTO_PORT),
    idePort: Number(args['ide-port'] || DEFAULT_IDE_PORT)
  });
  const results = [];
  try {
    for (const route of routes) {
      await connected.miniProgram.reLaunch(route);
      const page = await connected.miniProgram.currentPage();
      results.push({ route, pass: page?.path === route.slice(1) });
    }
  } finally {
    try { await connected.miniProgram.disconnect(); } catch {}
  }
  console.log(JSON.stringify(results, null, 2));
  if (results.some((item) => !item.pass)) process.exitCode = 1;
}

main().catch((error) => {
  console.error(JSON.stringify({ pass: false, error: error.message }, null, 2));
  process.exitCode = 1;
});
