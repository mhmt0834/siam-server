# 餐饮 SaaS 生产部署

生产部署入口：

1. 执行 `mvn -Pprod -pl siam-system/system-provider -am clean package -DskipTests` 生成 `siam-server.jar`。
2. 复制 `.env.production.example` 为 `.env.production`，仅在服务器填写实例值和密钥。
3. 执行 `docker compose --env-file .env.production -f docker-compose.production.yml config` 校验配置。
4. 按 [生产部署方案](../docs/生产部署方案.md) 完成 DNS、HTTPS、启动、备份和监控。

任何 `.env.production`、证书、AppSecret、支付 Key、商户私钥和数据库密码都不得进入 Git、前端、日志或模板压缩包。
