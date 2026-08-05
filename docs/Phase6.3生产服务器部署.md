# Phase 6.3 生产服务器部署

## 目标环境

- Ubuntu 22.04 LTS，2 vCPU / 2 GiB / 40 GiB ESSD。
- 部署根目录：`/opt/restaurant-saas`。
- 对外仅开放 `22`、`80`、`443`；MySQL、Redis、MongoDB 和后端端口只在 Docker 内部网络可见。
- 当前阶段使用 HTTP 验证，HTTPS、DNS 和微信合法域名在 Phase 6.4 完成。

## 目录

```text
/opt/restaurant-saas/
├── backend/source/    # Git 工作副本和生产 JAR
├── docker/            # Compose、Nginx 模板和仅服务器保存的 .env.production
├── nginx/certbot/     # ACME challenge 与证书目录
├── mysql/data/        # MySQL 持久化数据
├── redis/data/        # Redis AOF/RDB
├── mongo/data/        # MongoDB 持久化数据
├── logs/backend/
├── logs/nginx/
└── backup/
```

## 首次部署

```bash
cd /opt/restaurant-saas/backend/source
sudo deploy/scripts/init-ubuntu-22.04.sh

# 仅在服务器执行；脚本自动生成强随机密码，不回显密码。
sudo PUBLIC_DOMAIN=api.example.com \
  WECHAT_APP_ID=wx-merchant-instance \
  MERCHANT_ORIGIN=https://admin.example.com \
  deploy/scripts/create-production-env.sh

sudo deploy/scripts/deploy-production.sh
```

`create-production-env.sh` 拒绝覆盖已有环境文件。需要变更单个配置时，应先备份并使用服务器编辑器修改 `/opt/restaurant-saas/docker/.env.production`，权限保持 `600`。

## 2C2G 限制

- 必须保留 2 GiB swap，`vm.swappiness=20`。
- Spring Boot：容器 768 MiB，堆 256–512 MiB，Serial GC，Tomcat 80 线程。
- MySQL：容器 512 MiB，InnoDB Buffer Pool 256 MiB，最大连接 60。
- Redis：容器 160 MiB，`maxmemory=128mb`，`noeviction`，AOF `everysec`。
- MongoDB：容器 384 MiB，WiredTiger Cache 256 MiB。
- Nginx：容器 96 MiB；所有容器日志轮转为 10 MiB × 3。

该配置只适合首批少量试运营商家。内存持续超过 80%、出现 swap 高频读写或 Java OOM 时，应优先升级到 2C4G，不应继续压缩数据库缓存。

## 数据库初始化与验收

MySQL 空数据目录首次启动时依次执行：

1. `docs/phase1-acceptance/schema-phase1.sql`：只创建表结构，不导入演示账号和历史订单。
2. `sql/mysql/update.sql`：幂等增加餐桌、购物车隔离、订单、支付配置和索引。
3. `sql/mysql/yuking_template.sql`：保持店内到店付款安全默认值。

部署脚本会再次执行幂等迁移。验收脚本检查六张核心表、六个 `shop_id` 隔离字段、四组关键索引、MySQL/Redis/MongoDB 连通性和后端健康状态。

## 回滚

```bash
cd /opt/restaurant-saas/docker
docker compose --env-file .env.production -f docker-compose.production.yml images
docker compose --env-file .env.production -f docker-compose.production.yml up -d --no-build
```

回滚前先执行 `/opt/restaurant-saas/docker/scripts/backup.sh`。代码回退使用已推送的 `codex/backup-*` 分支；数据库结构只允许通过已验证的恢复流程回退，不直接删除生产表。
