---
name: wechat-miniapp-debug-loop
description: "Run an evidence-based WeChat mini-program debug loop through miniprogram-automator and WeChat Developer Tools CLI first, with Computer Use reserved for visual confirmation. Reproduce real page interactions, capture runtime requests/Console, correlate backend and database evidence, apply the smallest safe fix, rebuild, and repeat. Use for login failures, unresponsive buttons, blank pages, real-device errors, red Console errors, failed requests, Developer Tools errors, API failures, or end-to-end mini-program verification."
---

# 微信小程序调试闭环

Use this runtime priority and do not reorder it:

1. `miniprogram-automator` over the Developer Tools automation WebSocket.
2. WeChat Developer Tools CLI and any available CLI agent capability.
3. Computer Use for final visual, Console, and Network assistance only.
4. Ask the user only for a physical-phone-exclusive action.

Do not repeatedly inject mouse input into an NW.js window after one confirmed window-ownership failure. A blocked Computer Use visual check does not invalidate an Automator E2E that has complete runtime evidence.

## 1. Protect the test boundary

1. Read [references/project-map.md](references/project-map.md), then run `scripts/preflight.ps1` before changing anything.
2. Record HEAD, branch, dirty files, services, Developer Tools state, and the exact SHA-256 of `uniapp-siam-user/manifest.json`.
3. Treat every pre-existing dirty file as user-owned. Never stage, overwrite, revert, format, or auto-fix `manifest.json`.
4. Keep `restaurant-saas-v1.7-rc1` frozen. Do not change production config, payment core, authentication, authorization, or shopId isolation unless the request explicitly authorizes that exact scope.
5. Before the first code/config edit, run the safe code-change workflow and push a secret-safe rollback branch. Exclude secrets, generated builds, dependency directories, and the protected manifest.
6. Never deploy, upload, enable payment, change production data, weaken security, fake a token/Storage value, or replace UI E2E with a direct backend request.
7. Before and after HBuilderX builds, byte-compare the protected manifest. Restore only a tool-induced mutation from the same-run snapshot; never restore across a concurrent user edit.

## 2. Establish the automation channel

Use the Skill-local Node project in `scripts/`; never install `miniprogram-automator` into a business frontend or production dependency tree.

1. Verify Developer Tools is installed and logged in with CLI `islogin`.
2. Verify Developer Tools `设置 → 安全设置 → 服务端口` is enabled. A CLI connection failure is evidence to inspect this setting; do not change business code.
3. Compile/open the generated `uniapp-siam-user/unpackage/dist/dev/mp-weixin` project, not the source directory.
4. Start automation through the installed package's real `Launcher` behavior: spawn `cli auto --auto-port 9420 --project <generated-project> --trust-project` and attempt the WebSocket connection concurrently. Do not wait for a standalone CLI command to finish before connecting; the automation port may be short-lived without a client.
   - Prefer the official stable sequence: `cli open --project <generated-project>` → wait for project load → `cli auto --auto-port 9420 --project <generated-project>` → connect immediately.
   - verify TCP 9420 is listening
   - connect and execute an Automator protocol call such as `currentPage()`
5. Treat a listening port without a successful protocol call as FAIL. If port 9420 hosts the IDE HTTP service instead of Automator WebSocket, quit the IDE once and relaunch with the sequence above.
6. Run `node scripts/devtools-connect.mjs --project <generated-project>` for the repeatable connection check.
7. Retry CLI open/auto/connect up to three clean rounds. Preserve the actual error after the third failure.

The CLI service port and `--auto-port` are different roles even if both can be assigned 9420 at different times. Never occupy the Automator port with `cli --port 9420` during an Automator run.

## 3. Capture runtime evidence

Use `scripts/collect-runtime.mjs` from the E2E driver to instrument, not mock, real `wx.request` and `wx.login` calls. The wrapper must call the original API and preserve callbacks.

Capture and redact:

- page route and selected visible text;
- request URL, method, status code, and sanitized response shape;
- `wx.login` success as `hasCode: true/false`, never the code;
- Console error-level records and runtime exceptions;
- Storage presence as booleans, never token/openId/phone values;
- screenshots and a JSON evidence file outside Git.

Never persist authorization headers, cookies, codes, session keys, access tokens, AppSecret, SMS codes, payment material, or full phone numbers.

For each failure, build:

`UI symptom → Automator page action → runtime request/response → Console → backend log → database evidence → code path → root cause`

## 4. Drive real UI interaction

Use Automator element actions (`page.$`, `page.$$`, `element.tap`, `element.input`) from the real user entry route. Do not call a page login method, synthesize Storage, or call the login API directly.

When Automator connects but `Page.getElement`/`Page.getElements` times out, do not fall back to Computer Use. Diagnose in this fixed order:

`currentPage → route/query/pageStack → page load state → actual generated WXML → wx:if → custom-component boundary → stable id/class selector → conditional wait → element.tap`

Rules for this failure mode:

1. Run `node scripts/inspect-page-elements.mjs` and record the current route, query, page stack, page data readiness, selector counts, and node types. Do not guess selectors from visible text.
2. Inspect the source Vue/WXML and generated WXML. Confirm whether the real clickable node is conditionally rendered, slotted, covered, or implemented as a custom component.
3. Prefer a stable `id` on the existing real clickable node. Adding an id is allowed only when it changes neither style nor business behavior.
4. For a custom component, locate the host first; use its real `CustomElement` query scope only when the installed typings/API support it. Tapping a host with the original `bindtap` is valid UI interaction; `page.callMethod()` is not.
5. Wait for the expected route and selector to exist; never replace a condition wait with a longer blind sleep.
6. If `currentPage()` itself fails or Page protocol calls never respond, treat this as a Developer Tools/project-loading channel failure before changing selectors. Check the exact installed `miniprogram-automator` API and Developer Tools protocol response.
7. If `pageStack()` is empty, use one normal mini-program `reLaunch` to the configured home route and condition-wait for page metadata. This repairs first-launch registration without calling business methods. If the stack stays empty, inspect Developer Tools logs for `routeTo appLaunch timeout`, `isMiniAppProject=false`, and an empty internal `appid` before touching selectors.
8. On Windows, if the Developer Tools CLI persists a Chinese project path as mojibake, use a Skill-local physical copy of the generated build for testing. Verify `isMiniAppProject` and internal AppID in the tool log; an ASCII junction alone can be misclassified by some Developer Tools builds. Never copy or modify business source.
9. Developer Tools `2.02.2607271` may return `Tool.getInfo.version` without legacy `SDKVersion` and may misclassify a valid generated mini-program as `isMiniAppProject=false`. Keep compatibility adapters inside this Skill; verify with a stable Developer Tools build before changing application code.
10. Keep the installed package/API sequence fixed after transport connects:

`currentPage/pageStack → route/load readiness → generated WXML → wx:if → component host → stable selector → condition wait → element.tap`

Never fall back to Computer Use merely because `getElement` timed out.

For login, run `node scripts/login-e2e.mjs` with test credentials supplied only through process environment:

- `WECHAT_E2E_PHONE`
- `WECHAT_E2E_SMS_CODE`
- optional `WECHAT_BACKEND_LOG`

The script must execute real `element.tap()` calls for each login entry:

`我的 → 登录/注册 → 手机号验证码登录 → 输入 → 点击确定 → wx.login → code2Session → backend login → MySQL → token → Storage → /me → logged-in UI → reload → persisted login`

If the selected flow requires a real phone authorization, SMS, QR scan, camera, OS permission, or payment confirmation that Automator cannot perform, stop exactly there and say `请在手机完成 XXX，完成后告诉我继续。` Never bypass that step.

Use `scripts/ui-regression.mjs` for a non-destructive route/visibility regression after the focused fix. Do not expand a narrowly scoped task into unrelated functional acceptance.

## 5. Diagnose and fix

Check red Console errors, unhandled rejections, JS runtime errors, `request:fail`, domain/HTTPS/SSL failures, 401/403/404/500, `wx.login` or code2Session failures, AppID mismatch/missing, token/session problems, missing/cross-tenant shopId, WebSocket failures, database errors, blank pages, inert controls, duplicate requests, and API field mismatches.

1. Trace only the failing handler, request wrapper, backend endpoint, log source, and required shared dependency.
2. Apply the smallest compatible patch while preserving architecture and UI.
3. Keep authorization and shopId derivation server-side. Never trust a client-supplied shopId for access control.
4. Never hide an error with an empty catch, log suppression, disabled validation, fabricated success, hard-coded shopId, or weakened payment/authentication checks.
5. Re-check the protected manifest hash after every edit and build.

## 6. Rebuild and repeat

After every patch:

1. Recompile the affected module.
2. Restart only required local services.
3. Start a fresh Automator session through CLI.
4. Repeat the identical UI route and actions.
5. Reinspect captured requests, Storage presence, Console, backend logs, and database state.
6. Continue `locate → patch → build → Automator UI retest → evidence check` until the target works without related errors or regressions.

Compilation or source review alone is never PASS.

## 7. Separate the three evidence gates

After Automator E2E, use Computer Use once for final visible page state and Developer Tools Console/Network when available. If the NW.js window remains inaccessible, record it separately and stop mouse-injection retries.

Always report:

- `AUTOMATOR E2E: PASS/FAIL`
- `VISUAL COMPUTER USE: PASS/BLOCKED`
- `PHYSICAL DEVICE: PASS/BLOCKED`

An Automator-proven business flow may pass when visual Computer Use is blocked. Physical-device PASS requires an actual device run; never infer it from the simulator.

## 8. LOGIN AUTOMATION PASS gate

Report `LOGIN AUTOMATION PASS` only when all are true:

- Automator triggers login from the UI page entry.
- WeChat code2Session succeeds.
- A real token is generated without being exposed.
- Token Storage presence is confirmed from the running mini program.
- `/me` succeeds and identifies the current user.
- The UI changes to logged-in state.
- Reload preserves login state.
- Backend related ERROR count is zero.
- Application-related Console red-error count is zero.

Otherwise report the single earliest failing gate and its evidence. Do not convert an NW.js Computer Use limitation into a business login failure when the Automator evidence is complete.

## 9. Report

Use [references/report-template.md](references/report-template.md). Include the manifest hash check, rollback branch/SHA, evidence directory, final diff, and whether a commit is recommended. Do not auto-commit unless requested.
