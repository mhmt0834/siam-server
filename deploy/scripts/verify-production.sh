#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE="${1:-/opt/restaurant-saas/docker/.env.production}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/env-file.sh
source "${SCRIPT_DIR}/lib/env-file.sh"
DEPLOY_ROOT="$(env_file_value_or_default "${ENV_FILE}" DEPLOY_ROOT "/opt/restaurant-saas")"
PUBLIC_DOMAIN="$(env_file_value_or_default "${ENV_FILE}" PUBLIC_DOMAIN "")"
if [[ -z "${PUBLIC_DOMAIN}" ]]; then
  echo "PUBLIC_DOMAIN is required." >&2
  exit 1
fi
COMPOSE_FILE="${DEPLOY_ROOT}/docker/docker-compose.production.yml"

compose=(docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}")
"${compose[@]}" ps

"${compose[@]}" exec -T mysql \
  sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin ping -h 127.0.0.1 -u"$MYSQL_USER" --silent'
"${compose[@]}" exec -T redis \
  sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli ping' | grep -q '^PONG$'
"${compose[@]}" exec -T mongodb sh -c \
  'exec mongosh --quiet --host 127.0.0.1 --username "$MONGO_ROOT_USERNAME" --password "$MONGO_ROOT_PASSWORD" --authenticationDatabase admin --eval '\''quit(db.adminCommand({ping:1}).ok ? 0 : 2)'\'''

schema_result=$("${compose[@]}" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "
    SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN
        (\"tb_dining_table\",\"tb_shopping_cart\",\"tb_order\",\"tb_order_detail\",\"tb_shop_wechat_config\",\"tb_wechat_payment_record\");
    SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA=DATABASE() AND COLUMN_NAME=\"shop_id\"
        AND TABLE_NAME IN (\"tb_goods\",\"tb_menu\",\"tb_shopping_cart\",\"tb_order\",\"tb_shop_wechat_config\",\"tb_wechat_payment_record\");
    SELECT COUNT(DISTINCT CONCAT(TABLE_NAME,\":\",INDEX_NAME)) FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA=DATABASE() AND INDEX_NAME IN
        (\"idx_cart_member_shop_table\",\"idx_order_shop_status_time\",\"idx_order_member_shop_time\",\"uk_order_no\");"')

expected=$'6\n6\n4'
if [[ "${schema_result}" != "${expected}" ]]; then
  echo "Schema isolation verification failed: ${schema_result//$'\n'/,}" >&2
  exit 1
fi

for attempt in $(seq 1 36); do
  if curl -fsS -H "Host: ${PUBLIC_DOMAIN}" http://127.0.0.1/healthz 2>/dev/null | grep -q '"status":"UP"'; then
    break
  fi
  if [[ "${attempt}" -eq 36 ]]; then
    echo "Backend/Nginx health check did not become ready." >&2
    exit 1
  fi
  sleep 5
done
echo "PRODUCTION_VERIFY_OK tables=6 shop_columns=6 isolation_indexes=4 health=UP"
