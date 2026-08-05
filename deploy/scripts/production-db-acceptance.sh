#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
DEPLOY_DIR="${DEPLOY_ROOT}/docker"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
ORDER_FIXTURE_COUNT="${ORDER_FIXTURE_COUNT:-50000}"
READ_QUERY_COUNT="${READ_QUERY_COUNT:-5000}"
WRITE_QUERY_COUNT="${WRITE_QUERY_COUNT:-2000}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
for value in "${ORDER_FIXTURE_COUNT}" "${READ_QUERY_COUNT}" "${WRITE_QUERY_COUNT}"; do
  [[ "${value}" =~ ^[1-9][0-9]*$ ]] || {
    echo "Load counts must be positive integers." >&2
    exit 1
  }
done

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
QA_DB="siam_qa_phase642_$(date +%H%M%S)"
[[ "${QA_DB}" =~ ^siam_qa_phase642_[0-9]{6}$ ]]
LOAD_ENV="$(mktemp /tmp/restaurant-load-env.XXXXXX)"
chmod 600 "${LOAD_ENV}"
MYSQL_CONTAINER="$("${COMPOSE[@]}" ps -q mysql)"
docker exec "${MYSQL_CONTAINER}" env | grep -E '^(MYSQL_USER|MYSQL_PASSWORD)=' > "${LOAD_ENV}"

cleanup() {
  set +e
  if "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "DROP DATABASE IF EXISTS \`$QA_DB\`"' >/dev/null 2>&1; then
    echo "mysql_isolated_cleanup=OK"
  else
    echo "mysql_isolated_cleanup=FAILED" >&2
  fi
  rm -f "${LOAD_ENV}"
}
trap cleanup EXIT

LATEST_BACKUP="$(find "${DEPLOY_ROOT}/backup" -mindepth 1 -maxdepth 1 -type d -name '20*' -printf '%p\n' | sort | tail -n 1)"
MYSQL_BACKUP="$(find "${LATEST_BACKUP}" -maxdepth 1 -name 'mysql-*.sql.gz' -print -quit)"
test -s "${MYSQL_BACKUP}"
(cd "${LATEST_BACKUP}" && sha256sum -c SHA256SUMS >/dev/null)

"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "CREATE DATABASE \`$QA_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; GRANT ALL PRIVILEGES ON \`$QA_DB\`.* TO '\''$MYSQL_USER'\''@'\''%'\'';"'
gzip -dc "${MYSQL_BACKUP}" | "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql -u"$MYSQL_USER" "$QA_DB"'

RESTORE_SQL='SELECT CONCAT("restored_tables=", COUNT(*)) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE(); SELECT CONCAT("restored_orders=", COUNT(*)) FROM tb_order;'
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${RESTORE_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"'

read -r -d '' SEED_SQL <<SQL || true
INSERT INTO tb_order
  (member_id, order_no, goods_total_quantity, goods_total_price, actual_price,
   shopping_way, status, is_deleted, shop_id, shop_name, create_time, update_time,
   checkout_mode, table_no, is_payment, order_channel)
SELECT
  MOD(n, 10000) + 1,
  CONCAT('QA642', LPAD(n, 10, '0')),
  1, 68.00, 68.00, 1,
  CASE MOD(n, 3) WHEN 0 THEN 2 WHEN 1 THEN 3 ELSE 6 END,
  0, MOD(n, 50) + 1, 'QA Shop',
  NOW() - INTERVAL MOD(n, 30) DAY, NOW(), 1,
  CONCAT('T', MOD(n, 100)), IF(MOD(n, 3) = 2, 1, 0), 1
FROM (
  SELECT d0.n + 10*d1.n + 100*d2.n + 1000*d3.n + 10000*d4.n AS n
  FROM
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4
) sequence_values
WHERE n < ${ORDER_FIXTURE_COUNT};

INSERT INTO tb_order_detail
  (order_id, goods_id, goods_name, main_image, price, number, subtotal)
SELECT id, MOD(id, 10) + 1, CONCAT('QA Goods ', MOD(id, 10) + 1),
       'qa.jpg', 68.00, 1, 68.00
FROM tb_order
WHERE order_no LIKE 'QA642%';

ANALYZE TABLE tb_order, tb_order_detail;
SQL
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${SEED_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"' >/dev/null

COUNT_SQL='SELECT CONCAT("seed_orders=", COUNT(*), ", shops=", COUNT(DISTINCT shop_id)) FROM tb_order WHERE order_no LIKE "QA642%"; SELECT CONCAT("seed_details=", COUNT(*)) FROM tb_order_detail;'
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${COUNT_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"'

INDEX_SQL='SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns_used FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ("tb_order", "tb_order_detail", "tb_shopping_cart", "tb_dining_table") GROUP BY TABLE_NAME, INDEX_NAME ORDER BY TABLE_NAME, INDEX_NAME; EXPLAIN SELECT id, order_no, actual_price FROM tb_order WHERE shop_id=7 AND status=2 ORDER BY create_time DESC LIMIT 20;'
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${INDEX_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"'

READ_QUERY='SELECT SQL_NO_CACHE id, order_no, actual_price FROM tb_order WHERE shop_id=7 AND status=2 ORDER BY create_time DESC LIMIT 20'
WRITE_QUERY="INSERT INTO tb_order (member_id, order_no, shopping_way, status, is_deleted, shop_id, shop_name, create_time, update_time) VALUES (1, CONCAT('LOAD', REPLACE(UUID(), '-', '')), 1, 1, 0, MOD(CONNECTION_ID(), 50) + 1, 'Load Shop', NOW(), NOW())"

echo "mysql_read_peak=START"
docker run --rm --memory=256m --cpus=1.0 --network yuking-restaurant-saas_data \
  --env-file "${LOAD_ENV}" -e QA_DB="${QA_DB}" -e QA_QUERY="${READ_QUERY}" mysql:8.0 sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysqlslap -hmysql -u"$MYSQL_USER" --create-schema="$QA_DB" --concurrency=50 --iterations=3 --number-of-queries='"${READ_QUERY_COUNT}"' --query="$QA_QUERY"'
echo "mysql_write_peak=START"
docker run --rm --memory=256m --cpus=1.0 --network yuking-restaurant-saas_data \
  --env-file "${LOAD_ENV}" -e QA_DB="${QA_DB}" -e QA_QUERY="${WRITE_QUERY}" mysql:8.0 sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysqlslap -hmysql -u"$MYSQL_USER" --create-schema="$QA_DB" --concurrency=20 --iterations=3 --number-of-queries='"${WRITE_QUERY_COUNT}"' --query="$QA_QUERY"'

"${COMPOSE[@]}" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SHOW GLOBAL STATUS LIKE '\''Slow_queries'\''; SHOW VARIABLES LIKE '\''long_query_time'\'';"'
free -m | awk '/^Mem:/ {print "host_memory_available_mb=" $7}'
