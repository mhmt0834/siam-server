#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:?PUBLIC_DOMAIN is required}"
WECHAT_APP_ID="${WECHAT_APP_ID:-}"
MERCHANT_ORIGIN="${MERCHANT_ORIGIN:-https://yukingai.cn}"
ENV_FILE="${ENV_FILE:-${DEPLOY_ROOT}/docker/.env.production}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ -e "${ENV_FILE}" ]]; then
  echo "Refusing to overwrite existing ${ENV_FILE}." >&2
  exit 1
fi

random_hex() {
  openssl rand -hex 24
}

db_root_password=$(random_hex)
db_password=$(random_hex)
redis_password=$(random_hex)
mongo_root_password=$(random_hex)
mongo_app_password=$(random_hex)
payment_master_key=$(openssl rand -base64 32 | tr -d '\n')

umask 077
cat >"${ENV_FILE}" <<EOF
COMPOSE_PROJECT_NAME=yuking-restaurant-saas
TZ=Asia/Shanghai
DEPLOY_ROOT=${DEPLOY_ROOT}
PROJECT_SOURCE=${DEPLOY_ROOT}/backend/source

PUBLIC_DOMAIN=${PUBLIC_DOMAIN}
TLS_EMAIL=
NGINX_TEMPLATE=api-http.conf.template
BACKEND_IMAGE=yuking/restaurant-saas:1.6.3
JAVA_OPTS="-Xms256m -Xmx512m -XX:MaxMetaspaceSize=160m -XX:MaxDirectMemorySize=64m -XX:+UseSerialGC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs -Djava.security.egd=file:/dev/./urandom"
MERCHANT_WEBSOCKET_ALLOWED_ORIGINS=${MERCHANT_ORIGIN}

BACKEND_MEMORY_LIMIT=768m
BACKEND_CPU_LIMIT=1.25
MYSQL_MEMORY_LIMIT=512m
MYSQL_CPU_LIMIT=0.75
MYSQL_INNODB_BUFFER_POOL_SIZE=256M
MYSQL_MAX_CONNECTIONS=60
REDIS_MEMORY_LIMIT=160m
REDIS_CPU_LIMIT=0.25
REDIS_MAXMEMORY=128mb
MONGO_MEMORY_LIMIT=384m
MONGO_CPU_LIMIT=0.50
MONGO_WIREDTIGER_CACHE_GB=0.25
NGINX_MEMORY_LIMIT=96m
NGINX_CPU_LIMIT=0.25
DOCKER_LOG_MAX_SIZE=10m
DOCKER_LOG_MAX_FILES=3

SERVER_MAX_THREADS=80
SERVER_ACCEPT_COUNT=50
DB_POOL_MAX_SIZE=8
DB_POOL_MIN_IDLE=2
REDIS_POOL_MAX_ACTIVE=12
REDIS_POOL_MAX_IDLE=4
REDIS_POOL_MIN_IDLE=1

DB_NAME=siam_db
DB_APP_USER=siam_app
DB_ROOT_PASSWORD=${db_root_password}
DB_PASSWORD=${db_password}
REDIS_PASSWORD=${redis_password}

MONGO_ROOT_USERNAME=siam_root
MONGO_ROOT_PASSWORD=${mongo_root_password}
MONGO_APP_DATABASE=siam_db
MONGO_APP_USER=siam_app
MONGO_APP_PASSWORD=${mongo_app_password}
MONGODB_URI=mongodb://siam_app:${mongo_app_password}@mongodb:27017/siam_db?authSource=siam_db

PAYMENT_CONFIG_MASTER_KEY=${payment_master_key}
WECHAT_PAY_NOTIFY_BASE_URL=https://${PUBLIC_DOMAIN}
WECHAT_APP_ID=${WECHAT_APP_ID}
WECHAT_APP_SECRET=
WECHAT_OPEN_APP_ID=
WECHAT_OPEN_APP_SECRET=

ALIYUN_OSS_ACCESS_KEY_ID=
ALIYUN_OSS_ACCESS_KEY_SECRET=
ALIYUN_OSS_ENDPOINT=
ALIYUN_OSS_BUCKET=
BAIDU_MAP_AK=
XINYEYUN_USER=
XINYEYUN_KEY=
EOF
chmod 600 "${ENV_FILE}"
unset db_root_password db_password redis_password mongo_root_password mongo_app_password payment_master_key
echo "Created protected production environment file: ${ENV_FILE}"
