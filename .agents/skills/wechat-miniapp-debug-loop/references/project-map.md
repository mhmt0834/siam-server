# 扫码点餐系统开发映射

- Git 根目录：`C:\Users\Administrator\Documents\扫码点餐系统\siam-server`
- 小程序源码：`uniapp-siam-user`
- 微信开发者工具导入目录：`uniapp-siam-user\unpackage\dist\dev\mp-weixin`
- 受保护文件：`uniapp-siam-user\manifest.json`（允许读取；禁止自动覆盖、暂存或提交用户原有改动）
- Spring Boot provider：`siam-system\system-provider`
- 本地后端端口：`9200`
- 基础服务：MySQL `3306`、Redis `6379`、MongoDB `27017`
- 正式候选基线：`restaurant-saas-v1.7-rc1`

## 构建与运行

- 小程序没有可靠的 npm `mp-weixin` 构建脚本，使用已安装 HBuilderX 生成产物，再由微信开发者工具加载生成目录。
- 验收构建使用 `cli.exe launch mp-weixin --project <source> --continue-on-error false --runtime-log false`；不要用 `runtime-log true` 做最终 Console 判定。
- HBuilderX CLI 可能把源码 `manifest.json` 中有效的微信 AppID 改成 `null`。调用前必须保存原始字节和 SHA-256，调用后逐字节校验；只恢复本次工具造成的变化。
- 微信开发者工具官方自动化使用生成目录。默认运行 `node scripts/devtools-connect.mjs`，按 `cli open → cli auto --auto-port 9420 --project → automator.connect` 建立真实页面驱动。
- `--auto-port` 是 `miniprogram-automator` WebSocket 端口，不是 IDE HTTP 服务端口。不要用 `cli --port 9420` 抢占同一端口。
- `miniprogram-automator` 是页面交互、Storage、Console/exception 和请求证据的第一通道；Computer Use 只做最终可视核验。NW.js 窗口归属错误不得触发重复鼠标注入。
- 后端 jar 不包含真实 `application-local.yml`，本地启动必须显式追加外部配置：`--spring.profiles.active=local --spring.config.additional-location=file:<application-local.yml>`。
- 端口 9200 监听不代表数据库健康；至少执行一次真实只读 API，并同时检查 Hikari/MySQL、Redis、MongoDB 日志。
- 老板端 `node-sass@4` 与新 Node ABI 不兼容。使用仓库外临时 Node 12 执行现有构建，不升级依赖。
- 不安装缺失的 MySQL/MongoDB，不连接生产数据库，不执行真实支付，除非用户明确授权。

## 证据与隐私

- AppID 只记录“已配置/缺失/不一致”；不输出 AppSecret、session key、支付密钥或登录 code。
- UI 截图不得显示真实顾客手机号、验证码、Token 或支付凭据；测试值也应在报告中掩码。
- Developer Tools CLI 输出“使用 AppID”只证明项目配置被识别，不能替代 UI、Console、Network 或真机验收。
