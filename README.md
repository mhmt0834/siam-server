# 玉KING智能点餐

可复用的餐饮点餐程序模板，包含微信小程序用户端、Vue 管理后台和 Spring Boot 服务端。首发默认使用单门店、到店自取/门店外送、到店付款模式；微信支付、积分商城和裂变营销默认关闭。

## 目录

- `uniapp-siam-user`：微信小程序用户端
- `vue-siam-admin`：餐饮运营后台
- `siam-system`：Java API 服务
- `sql/mysql`：MySQL 初始化与模板迁移
- `restaurant-template.config.json`：新门店公共配置
- `上线任务清单.md`：提审流程与老板确认项

## 本地运行

1. 启动 MySQL、Redis，并导入 `sql/mysql` 数据。
2. 在 `siam-system/system-provider/src/main/resources` 中复制 `application-local.example.yml` 为 `application-local.yml`，只在本地或托管密钥中填写敏感配置。
3. 启动后端后访问 `http://127.0.0.1:9200/siam-server/actuator/health`。
4. 管理后台在 `vue-siam-admin` 执行 `npm install`、`npm run dev`。
5. 使用 HBuilderX 打开 `uniapp-siam-user`，运行到微信开发者工具。

## 新餐厅

先完成清单第 6 步，再使用 `$yuking-restaurant-launch` 注入店名、AppID、HTTPS API、地图 Key 和功能开关。AppSecret、支付密钥、证书及证照不得进入前端、Git 或模板压缩包。

## 重复工作自动化

- `安全改码流程.md`：所有修改自动按阶段连续检查，仅在真实阻塞或高风险外部操作时暂停。
- `scripts/apply_restaurant_config.ps1`：校验并注入门店公共配置；首次运行必须加 `-ValidateOnly`。
- `deploy/Caddyfile.template`：复用 HTTPS 反向代理和安全响应头，真实域名写入服务器本地环境。
- `privacy-data-map.json`：逐项记录小程序收集的数据、用途、功能开关及商家确认状态。
- `scripts/check-secrets.ps1`：打包前扫描硬编码密钥、私钥和证书文件，不输出密钥内容。
- `scripts/check-mini-program-dependencies.ps1`：检查 WXML、WXSS、WXS、JS 和组件配置的相对依赖。
- `scripts/build-all.ps1`：构建管理后台和微信小程序。
- `scripts/preflight-release.ps1`：检查 AppID、HTTPS、隐私确认、支付确认、包体积、服务健康和密钥泄露。

模板只保存 `.env.example` 和 `application-local.example.yml`；每家店的真实密钥必须保存在服务器环境或托管密钥中。
`uniapp-siam-user/wxcomponents/dist/vant/common` 和 `vant/wxs` 是 Vant 共用依赖，不得在精简组件时删除；预检会检查它们及构建后的全部相对引用。

## 许可与来源

项目按根目录 `LICENSE` 的 Apache-2.0 条款使用，并基于公开的餐饮点餐项目继续开发。发布衍生版本时保留许可证和必要版权说明。
