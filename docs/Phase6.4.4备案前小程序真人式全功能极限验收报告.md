# Phase 6.4.4 备案前小程序真人式全功能极限验收报告

## 结论

**结论：BLOCKED（有充分技术证据）**。

本轮完成了微信开发者工具真实点击、输入、Console/Network 检查、后端日志关联、最小修复和同路径复验；共确认 5 个产品 BUG，已修复 5 个。可达 UI 的相关 Console 红错已清零，单击“加入购物车”的请求由 2 条降为 1 条。

未达到整阶段 PASS 的原因不是 ICP，而是本机 MySQL `3306`、MongoDB `27017` 无服务/无可执行程序，Docker、Maven 也不存在。Spring Boot 能在 `9200` 启动，但所有数据库业务请求最终由 Hikari 报 `Connection refused`。因此真实登录成功、真实数据写入、shopId 越权攻击、订单状态机及 WebSocket 商户隔离无法形成“UI + 后端 + 数据库”闭环。

## 基线与保护

- 冻结标签：`restaurant-saas-v1.7-rc1`（`8288980d...`），未移动、未修改。
- 开始分支：`codex/template-responsibility-rules`。
- 开始 commit：`98c53afc3ad97fa72b4fe302c9c523520e989a75`。
- 回滚分支：`codex/backup-20260810-before-phase644`，已推送远端 `backup`。
- 用户原有脏文件：`uniapp-siam-user/manifest.json`。
- 测试前后 `manifest.json` SHA-256：`FBE133A315448B710141B0D60B0444ABA75F7EB834E3CF9BA550C07E19EDCC5E`，一致。
- `manifest.json` 未暂存、未提交；HBuilderX CLI 曾把 AppID 改成 `null`，已按测试前精确快照恢复。
- 未修改支付核心、shopId 隔离、鉴权、订单状态机、生产配置或数据库结构。

## 环境结果

| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 微信开发者工具 | 可运行 | Stable `2.01.2510290`，官方 CLI 识别已配置 AppID |
| 小程序编译 | 通过 | HBuilderX 5.07 `launch mp-weixin` 明确输出“编译成功” |
| 老板端构建 | 通过 | 使用仓库外临时 Node 12 构建；仅资源体积告警 |
| 管理端构建 | 通过 | 本轮前置构建成功 |
| Spring Boot | 能启动 | 外置 `application-local.yml` 后监听 `9200` |
| MySQL | BLOCKED | `127.0.0.1:3306` 拒绝连接；本机无 MySQL 服务/程序 |
| Redis | 可用 | Memurai，`127.0.0.1:6379` 可连接 |
| MongoDB | BLOCKED | `127.0.0.1:27017` 拒绝连接；本机无 MongoDB 服务/程序 |
| Docker | BLOCKED | 本机无 Docker 命令/服务 |
| Maven | BLOCKED | 本机无 Maven；使用已有 jar 启动 |

后端必须显式使用：`--spring.profiles.active=local --spring.config.additional-location=file:<application-local.yml>`。仅端口监听不能视为健康，登录与首页请求均在约 11 秒后返回统一业务失败，后端对应 `CJCommunicationsException` / `java.net.ConnectException: Connection refused`。

## 实际 UI 操作路径

### 消费者端真实后端路径

1. 启动小程序 → 首页。
2. 实际点击底部“订单” → 显示“登录后查看订单”。
3. 点击“去登录” → 登录方式页。
4. 点击“微信手机号登录” → 开发者工具显示“暂不支持微信登录，请选择验证码登录”。
5. 点击“手机号验证码登录” → 验证码登录页。
6. 空输入点击：按钮禁用，无请求。
7. 输入非法短手机号：获取验证码保持禁用，无请求。
8. 输入掩码测试手机号和测试验证码 → 点击“确定”。
9. 查看 Console、Network、后端日志。
10. 修复后关闭/重开开发者工具，从首页重复 1—9。
11. 模拟 `scene=invalid-phase644` 启动 → 菜单页明确显示“二维码无效 / 请重新扫描餐桌二维码”，可返回首页。
12. 点击“我的” → 登录/注册、我的订单、收藏、优惠活动、反馈、设置、关于页面入口正常显示。

### 临时 mock 的 UI 补测

为避免把缺失数据库扩大成整个前端不可测，本轮在仓库外启用一次性内存 mock，并仅临时修改被忽略的生成产物地址；测试后已恢复 `127.0.0.1:9200`、停止 mock，未写入仓库源码或生产数据。

路径：模拟有效桌码 → 桌号 A01 → 菜单 → 分类列表 → 点击菜品加号 → 规格弹层 → 单击加入购物车 → 购物车数量/金额刷新。

- 菜单真实渲染：推荐、主食；新疆大盘鸡、烤羊肉串、手抓饭。
- 规格真实渲染：标准份。
- 修复前单击一次：Network 出现 2 条 `shoppingCart/insert`，数量变 2。
- 修复后单击一次：Network 仅 1 条 `insert`（HTTP 200，54ms），数量为 1、金额 ¥68。
- mock 只能证明前端 UI、事件和状态刷新，不能替代真实后端金额重算、鉴权、shopId 隔离和数据库结果，因此这些项目没有标 PASS。

### 老板端真实页面

- 本地加载 `vue-siam-shop/dist`，DOM 显示“商家登录”、账号、密码、登录、开店、忘记密码、手机验证登录。
- 实际点击空白“登录”后出现“请输入账号”“请输入密码”。
- 页面 Console error：0。
- 真实老板登录及业务页因数据库与账号数据不存在而 BLOCKED。

## Console / Network / 后端日志

### 登录修复前

- Console：6 个红色错误，包含未处理 Promise；同时输出了 `wx.login` 临时代码及登录表单敏感值。
- Network：`POST http://127.0.0.1:9200/siam-server/rest/member/verification/login`，HTTP 200，约 11.27 秒，343B。
- Response：`success:false`、`code:0`、`message:"系统异常，请稍后重试"`。
- 后端：Hikari 初始化失败，MySQL `Connection refused`。

### 登录修复后

- 同一路径实际点击。
- Console：相关红色错误 0；手机号、验证码、`wx.login` code 不再输出。
- Network：相同 URL、POST、HTTP 200、约 11.21 秒、343B；业务失败体保持真实，没有伪造成功。
- 页面加载状态可结束，不再因业务失败产生 Promise rejection。
- 加载框重复 `hideLoading` 告警在第二次修复后消失。
- 后端仍准确记录 MySQL 连接拒绝，因此登录成功/Token/持久化按 BLOCKED 处理。

HBuilderX `--runtime-log true` 曾注入开发调试 WebSocket，导致工具自身 `closeSocket 1006` 红错。改用 `--runtime-log false` 并重开开发者工具后该工具错误消失；它不属于应用 WebSocket。

## 发现与修复的 BUG

| 编号 | 发现方式 | 根因 | 修复 |
| --- | --- | --- | --- |
| BUG-1 | 登录 UI + Console + Network | HTTP 200 业务失败时请求封装先 `reject` 又多次 `resolve` | 业务失败交给现有 `result.success` 分支，网络失败仍 reject，移除重复 settle |
| BUG-2 | 登录 UI/Console | 验证码登录页输出手机号和验证码 | 删除敏感日志 |
| BUG-3 | 启动 UI/Console | `App.onLaunch` 输出完整 `wx.login` 结果/code | 删除敏感日志，只在内存保存 code |
| BUG-4 | 慢请求 UI/Console | loading 3 秒自动关闭，响应后再次 hide，产生未配对告警 | 增加 loading 可见状态和定时器管理，只关闭一次 |
| BUG-5 | 菜单真实单击 + Network | `PrimaryButton` 原生 tap 冒泡和 `$emit('tap')` 双触发 | 根节点改为 `@tap.stop`，修复后单击仅 1 条插入请求 |

修改文件：

- `uniapp-siam-user/utils/http.js`
- `uniapp-siam-user/utils/toast.service.js`
- `uniapp-siam-user/App.vue`
- `uniapp-siam-user/pages/index/index.vue`
- `uniapp-siam-user/pages/internal/login/code/code.vue`
- `uniapp-siam-user/components/ui/primary-button.vue`

## 回归与异常测试

| 项目 | 结果 |
| --- | --- |
| 首页 API 失败 | PASS：显示错误/空状态，不白屏、不无限 loading |
| 订单页未登录状态 | PASS：显示登录入口 |
| 登录方式切换 | PASS：微信手机号限制有明确 Toast；验证码页可进入 |
| 登录输入边界 | PASS：空值/非法手机号不发请求 |
| 登录失败响应 | PASS（错误处理）：HTTP 200 业务失败被正常显示，Console 无红错 |
| 无效桌码 | PASS：明确“二维码无效”，不是空白页 |
| 有效桌码与菜单 UI | PASS（mock 限定）：A01、分类、菜品和规格可见 |
| 单次加入购物车 | PASS（mock 限定）：修复后单请求、数量 1、金额 ¥68 |
| 我的页面 | PASS：主要入口可见 |
| 老板端空表单 | PASS：真实页面校验提示正确，Console error 0 |
| 网络慢/数据库不可用 | PASS（客户端错误处理）：11 秒失败不再产生 Promise red error 或永久 loading |
| 页面退出/重新进入 | 部分 PASS：未登录/菜单可重入；登录持久化因真实登录 BLOCKED |
| 快速连点、购物车边界、订单重复提交 | BLOCKED：真实后端/数据库不可用；仅修复并验证了公共按钮单击双请求 |

## BLOCKED 项目与证据

### B1 真实登录成功、Token 与持久化

- 精确阻塞点：后端读取/写入会员数据时创建 MySQL 连接。
- 技术原因：`3306` 拒绝连接，本机没有可启动的 MySQL 服务或程序。
- 已尝试：外置 local 配置启动 jar、真实 UI 登录、Network/后端日志关联、AppID 检查、Redis 检查。
- 替代方案：mock 可证明前端 Token 存储路径，但不能证明后端 code2Session、Token 生成、会员数据和权限，故不足以 PASS。
- 外部条件：提供隔离的本地/测试 MySQL、MongoDB 和初始化测试数据。

### B2 真实菜单、详情、购物车、下单与订单状态机

- 精确阻塞点：有效桌码、商品、购物车、订单写入与状态转换的数据库访问。
- 已继续验证：无效桌码、有效桌码前端解析、菜单/规格/购物车 UI、重复插入前端 BUG。
- 未通过项：服务端价格重算、空/多商品、加减删除持久化、订单 1→2→3→6、非法转换拒绝、统计落库。
- 原因：mock 不能替代真实数据库约束与后端业务安全。

### B3 shopId 越权攻击与 WebSocket 商户隔离

- 精确阻塞点：创建 Shop A/B、merchant/member/table/goods/cart/order 数据及可信 Token。
- 已尝试：本地服务探测、后端启动、老板端页面、生成环境检查。
- 不使用生产 ECS/生产数据库：冻结规则禁止把验收测试数据和攻击请求打入生产。
- 外部条件：隔离测试数据库及 A/B 测试账号；随后执行跨店订单/商品/统计/批量/WebSocket 订阅攻击。

### B4 真机专属步骤

- 微信手机号授权、物理摄像头扫码、远程真机网络、支付确认需要用户手机。
- 开发者工具已验证入口与限制 Toast；未假装完成真机授权。
- 需人工步骤：`请在手机完成微信手机号授权和真实桌码扫描，完成后告诉我继续。`

## 支付与备案分类

- A 类（不依赖备案）：本轮未修改支付；静态安全结构和既有构建可检查，但真实回调/订单数据因测试数据库缺失未重新形成数据闭环。
- B 类（可由开发环境替代）：菜单和购物车前端主逻辑已用临时 mock 补测；真实后端支付前置数据仍需隔离测试库。
- C 类（必须备案后最终验证）：`HTTPS/WSS`、微信合法域名、真机正式域名扫码、¥0.01 用户确认支付、微信公网回调、支付后老板实时接单与统计最终一致性。
- 备案后最小补测链固定为：SSL → HTTPS/WSS → 微信合法域名 → 真机扫码 → ¥0.01 支付 → 回调 → 老板接单 → 统计。

## Skill

- 路径：`.agents/skills/wechat-miniapp-debug-loop/SKILL.md`
- 已实际用于本轮：保护基线 → 环境检查 → GUI 复现 → Console/Network → 后端日志 → 最小修复 → 编译 → 同路 GUI 复验 → 报告。
- 根据实测新增：NW.js Computer Use 内部错误的可见 GUI 回退链、官方 `--auto-port` 启动脚本、DPI-aware 点击要求、HBuilder manifest 保护、外置后端配置、Node 12 老板端构建、敏感日志红线、HTTP 业务失败证据规则。
- 新增脚本：`.agents/skills/wechat-miniapp-debug-loop/scripts/open-wechat-devtools.ps1`。
- 验证：PowerShell 语法全部通过；`quick_validate.py` 输出 `Skill is valid!`；启动脚本已实际连接 Developer Tools 并识别 AppID。
- Computer Use API：两次出现 NW.js 相同 owner 的内部窗口归属错误；随后使用官方 CLI/automator + 可见 DPI-aware OS GUI 完成真实点击、输入、Console 和 Network 检查。API 内部错误未被隐瞒。

## Git diff / commit

- 用户 `manifest.json` 改动保留且排除提交。
- 本次提交范围：6 个产品修复文件、Skill 及本报告。
- 未移动 `restaurant-saas-v1.7-rc1` 标签，未创建新生产标签。
- commit：提交完成后回填于 Git 历史；本报告所在提交即 Phase 6.4.4 修复提交。

## 最终未完成但仍可继续的项目

在“不安装未经授权的系统数据库、不连接生产、不执行真实支付”的边界内，没有剩余可继续形成真实后端/数据证据的项目。临时 mock 可覆盖的桌码、菜单、规格、购物车事件已继续完成；剩余项均精确依赖隔离测试数据库、测试账号、真机或备案后的正式网络条件。
