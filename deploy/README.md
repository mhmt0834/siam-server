# 餐饮 SaaS 生产部署

生产部署入口：

1. 执行 `mvn -Pprod -pl siam-system/system-provider -am clean package -DskipTests` 生成 `siam-server.jar`。
2. 复制 `.env.production.example` 为 `.env.production`，仅在服务器填写实例值和密钥。
3. 执行 `docker compose --env-file .env.production -f docker-compose.production.yml config` 校验配置。
4. 按 [生产部署方案](../docs/生产部署方案.md) 完成 DNS、HTTPS、启动、备份和监控。

Ubuntu 22.04 / 2C2G 首次部署：

1. 将仓库放到 `/opt/restaurant-saas/backend/source`。
2. 执行 `sudo deploy/scripts/init-ubuntu-22.04.sh`，安装 Docker、Compose、Git，建立 2GB swap、UFW 和生产目录。
3. 执行 `sudo PUBLIC_DOMAIN=api.example.com WECHAT_APP_ID=wx... deploy/scripts/create-production-env.sh`，在服务器生成权限为 `600` 的实例环境文件；不要复制回本机或 Git。
4. 执行 `sudo deploy/scripts/deploy-production.sh`，完成容器化构建、幂等迁移和生产验收。
5. 执行 `sudo /opt/restaurant-saas/docker/scripts/verify-production.sh` 可重复检查数据库、Redis、MongoDB、隔离字段/索引及健康状态。
6. 部署完成后会自动安装每日备份、每 5 分钟健康检查和日志轮转；用 `systemctl list-timers 'restaurant-saas-*'` 查看计划。
7. 空闲维护窗口执行 `sudo /opt/restaurant-saas/docker/scripts/production-db-acceptance.sh`，在临时数据库中验证 MySQL 备份恢复、索引与并发读写；脚本不修改生产业务库。
8. 执行 `sudo /opt/restaurant-saas/docker/scripts/production-restore-acceptance.sh`，在隔离的 MongoDB 临时库和 Redis 临时容器中验证恢复，成功后自动清理。
9. Phase 6.4.3 维护窗口依次执行 `production-index-acceptance.sh`、`production-business-acceptance.sh`、`production-gateway-acceptance.sh` 和 `production-api-load-acceptance.sh`，分别验收统计索引、全业务链路、网关限流/WebSocket 与 API 稳态负载；脚本均不得写入生产业务库。

Phase 6.3 使用 HTTP 模板验证内网与公网 IP；Phase 6.4 证书签发后将 `NGINX_TEMPLATE` 切换为 `api-https.conf.template`。

任何 `.env.production`、证书、AppSecret、支付 Key、商户私钥和数据库密码都不得进入 Git、前端、日志或模板压缩包。
