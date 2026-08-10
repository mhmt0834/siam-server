---
name: wechat-miniapp-debug-loop
description: "Run an evidence-based WeChat mini-program debug loop with Computer Use: reproduce in WeChat Developer Tools or visible real-device debugging, inspect Console and Network, correlate backend logs and code, apply the smallest safe fix, rebuild, repeat the same UI actions, and regress affected flows. Use for login failures, unresponsive buttons, blank pages, real-device errors, red Console errors, failed requests, WeChat Developer Tools errors, API failures, or requests to make or verify a mini-program feature end to end."
---

# 微信小程序调试闭环

Use Computer Use as the primary runtime evidence source. Never declare success from source review or compilation alone.

## 1. Establish the boundary

1. Resolve the Git root and read [references/project-map.md](references/project-map.md) when working in this repository.
2. Run `scripts/preflight.ps1` before changing anything. Record HEAD, branch, dirty files, service state, Developer Tools state, and the protected manifest hash.
3. Treat every pre-existing dirty file as user-owned. Never stage, overwrite, revert, format, or auto-fix `uniapp-siam-user/manifest.json`.
4. Treat `restaurant-saas-v1.7-rc1` as frozen. Do not modify production, payment core, authentication, authorization, or shopId isolation unless the current request explicitly authorizes that exact scope.
5. Before the first code/config edit, invoke the safe code-change workflow: scan secrets and push a secret-safe rollback branch at the recorded commit. Never include merchant instance secrets or the protected manifest in that backup.
6. Do not deploy, upload, enable payment, or change production data. Use local development/test data only.

## 2. Start and verify the development environment

1. Identify the mini-program source, generated `mp-weixin` directory, Spring Boot provider, build workflow, MySQL, Redis, and MongoDB from the repository rather than assuming paths.
2. Check ports and health before starting duplicates. Start only missing services with the project's existing commands.
3. Compile the backend and mini-program. A successful build is only a prerequisite, not PASS.
4. Launch HBuilderX and WeChat Developer Tools with Computer Use. Open the generated `unpackage/dist/dev/mp-weixin` project, not a source directory with a stale or empty `project.config.json`.
5. Confirm the generated project has a configured AppID without printing secrets. Do not edit the protected source manifest to fix a local Developer Tools import problem.
   - When manifest AppID is configured but the ignored generated `project.config.json` is empty, run `scripts/sync-generated-appid.ps1`. It updates only the generated artifact and verifies the protected manifest hash is unchanged.
6. If MySQL, MongoDB, or another required local service is not installed, do not install system software or point tests at production without authorization. Report the exact environment block.

## 3. Reproduce through the UI first

1. Use Computer Use to activate the exact WeChat Developer Tools window, refresh/recompile, and perform the user's operation from its real entry point.
2. Record the visible page state before and after every meaningful click.
3. Open Console and Network in Developer Tools. Capture relevant errors and requests; filter noise only after preserving evidence.
4. For login, execute: launch → login entry → login click → page result → Console → Network → request URL/status/response → `wx.login` result → backend log.
5. Do not infer that a button works because its handler exists. Do not call an API directly as a substitute for UI validation.

If Computer Use can list the NW.js window but cannot read/click it, close duplicate Developer Tools windows once, reopen the generated project, and retry once. The official Developer Tools CLI or `miniprogram-automator` may collect supplementary build/config evidence, but it cannot replace the required Computer Use/UI gate. Mark the run `BLOCKED`, not PASS, when actual UI, Console, or Network remains inaccessible.

## 4. Build an evidence chain

For every failure, record:

`UI symptom → Console/Network evidence → request → backend log → code path → root cause`

Check at minimum: red Console entries, unhandled rejections, JS runtime errors, `request:fail`, domain/HTTPS/SSL failures, 401/403/404/500, `wx.login` or code2Session failures, AppID mismatch/missing, token problems, missing/cross-tenant shopId, WebSocket errors, database errors, blank pages, inert controls, and API field mismatches.

Do not silence the symptom with an empty catch, log suppression, disabled validation, fabricated success response, bypassed authentication, weakened payment checks, or hard-coded shopId.

## 5. Apply the smallest fix

1. Trace only the failing UI handler, request wrapper, backend endpoint, log source, and shared dependency required by the evidence.
2. Patch the minimum files and preserve the existing architecture/UI.
3. Keep authorization and shopId derivation server-side. Never trust a client-supplied shopId for access control.
4. Re-check the protected manifest hash immediately after editing. Stop and restore only the skill-created change if it differs; never discard the user's original dirty content.

## 6. Rebuild and repeat until clean

After every patch:

1. Recompile the affected module.
2. Restart only required services.
3. Refresh/reopen the mini-program through Computer Use.
4. Repeat the identical UI route from the user entry point.
5. Reinspect Console, Network, backend logs, and resulting data.
6. Continue `locate → patch → build → UI retest → log check` until the feature works, relevant Console errors are absent, requests match expectations, backend logs are clean, and no new regression appears.

Do not label a pre-existing unrelated warning as fixed. Separate it from task-related failures.

## 7. Real-device debugging

When Developer Tools exposes computer-visible real-device/remote debugging, enter it with Computer Use and repeat the Console/Network loop. If a physical action is required, stop exactly there and say: `请在手机完成 XXX，完成后告诉我继续。` Never pretend to scan, authorize, grant OS permission, use a camera, or confirm payment on the user's phone.

## 8. Regression and PASS gate

Test the changed path plus, where reachable without real payment: home, table-scene parsing, menu, food details, cart, order confirmation/submission in a safe test environment, profile, login/session state, and affected merchant functions.

Report PASS only when all are true:

- Actual UI clicks pass.
- Relevant Console has no red error.
- Network requests have expected URL, status, and response.
- Backend logs contain no related ERROR.
- Data and authorization/shopId isolation are correct.
- No obvious affected-flow regression exists.

Otherwise report `BLOCKED` or `FAIL`, name the exact unverified gate, and do not weaken acceptance criteria.

## 9. Final report

Use [references/report-template.md](references/report-template.md). Include the pre/post Console, Network, backend logs, real-device status, manual phone step, regression result, `git diff`, protected manifest verification, rollback branch/commit, and whether a commit is recommended. Do not auto-commit unless the user asks.
