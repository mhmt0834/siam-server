# HTTPS 部署模板

1. 将 `.env.example` 复制为仅服务器保存的 `.env`，填写已备案域名和后端地址。
2. 在服务器环境中加载 `.env`，再使用 `Caddyfile.template` 启动 Caddy；Caddy 会自动申请并续期 HTTPS 证书。
3. 确认域名解析已指向服务器、80/443 端口开放，且 `https://域名/siam-server/actuator/health` 返回 `UP`。
4. 将同一 HTTPS 域名加入微信小程序 `request 合法域名`。

不要把 `.env`、证书、AppSecret、支付密钥或微信代码上传密钥放进 Git、前端或模板压缩包。
