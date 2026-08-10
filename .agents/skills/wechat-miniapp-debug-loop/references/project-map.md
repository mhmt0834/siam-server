# 扫码点餐系统开发映射

- Git 根目录：`C:\Users\Administrator\Documents\扫码点餐系统\siam-server`
- 小程序源码：`uniapp-siam-user`
- 微信开发者工具导入目录：`uniapp-siam-user\unpackage\dist\dev\mp-weixin`
- 受保护文件：`uniapp-siam-user\manifest.json`（允许读取，禁止自动修改、暂存或覆盖）
- Spring Boot provider：`siam-system\system-provider`
- 本地后端端口：`9200`
- 基础服务：MySQL `3306`、Redis `6379`、MongoDB `27017`
- 正式候选基线：`restaurant-saas-v1.7-rc1`

## 构建与运行提示

- 小程序 `package.json` 没有可用的 mp-weixin build script，优先通过已安装 HBuilderX 的“运行到微信开发者工具”生成产物。
- 可发现 HBuilderX `cli.exe` 后执行 `cli.exe launch mp-weixin --project <uniapp-siam-user绝对路径> --continue-on-error false --runtime-log true`；不要把机器上的版本化安装路径写死进产品代码。
- 微信开发者工具必须打开生成目录；源码根目录的 `project.config.json` 可能为空或过期，不能据此断言正式 AppID 未配置。
- 同时检查 manifest、源码 `project.config.json` 和生成目录 `project.config.json`。任一缺失或不一致都必须报告；不要把 Developer Tools 的本机缓存识别结果当成配置文件已修复。
- 微信开发者工具 CLI 的 `auto` 输出“使用 AppID”只能证明项目配置被识别，不能替代 UI、Console、Network 或真机验收。
- 验证 AppID 时只记录“已配置/缺失/不一致”，报告中不要输出 AppSecret、session key、支付密钥或登录 code。
- 后端使用仓库现有 Maven profile/build 命令；先检查是否已有健康进程，避免重复占用端口。
- 生产 ECS、生产数据库和真实支付不属于本 Skill 的默认测试范围。
