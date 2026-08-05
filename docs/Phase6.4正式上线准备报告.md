# Phase 6.4 正式上线准备报告

更新日期：2026-08-05

## DNS

- `api.yukingai.cn` 已添加 `A` 记录，指向 `120.26.179.11`，TTL 10 分钟。
- 权威 DNS、AliDNS、Cloudflare DNS 均返回 `120.26.179.11`。
- 生产服务器执行 `nslookup`、`ping`、`dig`、`curl` 均通过。
- 中国内地公网访问当前仍被阿里云备案拦截并返回 HTTP 403。

## HTTPS

- Nginx 已具备 TLS 1.2/1.3、HTTP 自动跳转 HTTPS、HSTS、WebSocket 反向代理模板。
- 已修复 ACME WebRoot 权限；源站挑战路径由 403 恢复为 200。
- 公网挑战路径仍被备案拦截为 403，当前不能完成 HTTP-01 签发，也不能切换 HTTPS 模板。
- 备案通过后申请证书，再将服务器环境中的 `NGINX_TEMPLATE` 切换为 `api-https.conf.template`，重建 Nginx 并配置每日续期检查。

## 微信小程序后台配置清单

AppID：`wx36934af633b83578`

备案和 HTTPS 验收通过后，由商家管理员进入「开发管理 → 开发设置 → 服务器域名」配置：

- request 合法域名：`https://api.yukingai.cn`
- uploadFile 合法域名：`https://api.yukingai.cn`
- downloadFile 合法域名：`https://api.yukingai.cn`
- socket 合法域名：`wss://api.yukingai.cn`

商家负责小程序主体、类目、资质、隐私与最终确认；授权开发管理员仅执行技术配置。AppSecret、上传私钥、支付密钥和证书私钥不得进入前端、Git、日志或模板。

## ICP 备案

阿里云备案控制台当前显示「尚无备案信息」。该中国内地 ECS 对外提供服务前必须完成备案。

单位备案准备：

- 与域名实名认证一致的主办单位信息和营业执照原件彩色资料；
- 法定代表人/主体负责人证件，网站负责人证件；
- 网站名称、服务内容、域名、服务器和联系方式；
- 如负责人不是法定代表人，按所在省管局要求准备授权书；
- 阿里云 App 人脸/真实性核验，保持备案电话畅通；
- 收到工信部短信后 24 小时内完成短信核验；
- 餐饮经营资质、隐私说明等由商家留存并按实际类目提交。

办理入口：[阿里云 ICP 备案](https://beian.aliyun.com/)

## 验收结果

- Docker：Spring Boot、MySQL、Redis、MongoDB、Nginx 均为 healthy。
- 源站健康检查：HTTP 200。
- WebSocket 未登录请求：HTTP 401，鉴权边界正常。
- 生产环境 `PUBLIC_DOMAIN` 与微信 AppID 配置匹配。
- HTTPS、WSS、微信合法域名、顾客端和老板端公网全流程：受 ICP 备案阻塞，未通过，不得标记正式上线。

## 下一步

1. 商家主体完成 ICP 备案并取得备案号。
2. 签发并部署证书，切换 HTTPS，验证 TLS、跳转、API 和 WSS。
3. 商家管理员配置微信合法域名并确认隐私/类目。
4. 进入 Phase 6.5：真实微信支付、真机扫码、商家确认后上传上线。
