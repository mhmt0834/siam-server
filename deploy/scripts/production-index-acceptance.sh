#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
DEPLOY_DIR="${DEPLOY_ROOT}/docker"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
ORDER_FIXTURE_COUNT="${ORDER_FIXTURE_COUNT:-50000}"
MODE="${MODE:-before}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
if [[ ! "${ORDER_FIXTURE_COUNT}" =~ ^[1-9][0-9]*$ ]]; then
  echo "ORDER_FIXTURE_COUNT must be a positive integer." >&2
  exit 1
fi
if [[ "${MODE}" != "before" && "${MODE}" != "after" ]]; then
  echo "MODE must be before or after." >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
QA_DB="siam_qa_phase643_${MODE}_$(date +%H%M%S)"
[[ "${QA_DB}" =~ ^siam_qa_phase643_(before|after)_[0-9]{6}$ ]]

cleanup() {
  set +e
  if "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "DROP DATABASE IF EXISTS \`$QA_DB\`"' >/dev/null 2>&1; then
    echo "mysql_isolated_cleanup=OK"
  else
    echo "mysql_isolated_cleanup=FAILED" >&2
  fi
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

read -r -d '' SEED_SQL <<SQL || true
INSERT INTO tb_order
  (member_id, order_no, goods_total_quantity, goods_total_price, actual_price,
   shopping_way, status, is_deleted, shop_id, shop_name, create_time, update_time,
   order_completion_time, checkout_mode, table_no, is_payment, order_channel)
SELECT
  MOD(n, 10000) + 1,
  CONCAT('QA643', LPAD(n, 10, '0')),
  1, 68.00, 68.00, 1,
  CASE MOD(n, 3) WHEN 0 THEN 2 WHEN 1 THEN 3 ELSE 6 END,
  0, MOD(n, 50) + 1, 'QA Shop',
  NOW() - INTERVAL MOD(FLOOR(n / 50), 30) DAY, NOW(),
  CASE WHEN MOD(n, 3) = 2 THEN NOW() - INTERVAL MOD(FLOOR(n / 50), 30) DAY ELSE NULL END,
  1, CONCAT('T', MOD(n, 100)), IF(MOD(n, 3) = 2, 1, 0), 1
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
  (order_id, goods_id, goods_name, main_image, price, number, subtotal, is_deleted)
SELECT id, MOD(id, 10) + 1, CONCAT('QA Goods ', MOD(id, 10) + 1),
       'qa.jpg', 68.00, 1, 68.00, 0
FROM tb_order
WHERE order_no LIKE 'QA643%';

ANALYZE TABLE tb_order, tb_order_detail;
SQL
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${SEED_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"' >/dev/null

if [[ "${MODE}" == "after" ]]; then
  echo "migration_run_1=START"
  "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" < /docker-entrypoint-initdb.d/02-migrations.sql'
  echo "migration_run_1=OK"
  echo "migration_run_2=START"
  "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" < /docker-entrypoint-initdb.d/02-migrations.sql'
  echo "migration_run_2=OK"
  "${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" -e "ANALYZE TABLE tb_order, tb_order_detail"' >/dev/null
fi

read -r -d '' PLAN_SQL <<'SQL' || true
SELECT CONCAT('fixture_orders=', COUNT(*), ',shops=', COUNT(DISTINCT shop_id))
FROM tb_order WHERE order_no LIKE 'QA643%';
SELECT CONCAT('fixture_details=', COUNT(*)) FROM tb_order_detail;
SELECT TABLE_NAME, INDEX_NAME,
       GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns_used
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('tb_order', 'tb_order_detail')
GROUP BY TABLE_NAME, INDEX_NAME ORDER BY TABLE_NAME, INDEX_NAME;
SET @sample_order_id=(SELECT MIN(id) FROM tb_order WHERE order_no LIKE 'QA643%');
SELECT 'PLAN_ORDER_DETAIL_BY_ORDER_ID';
EXPLAIN ANALYZE SELECT goods_id, goods_name, number, subtotal
FROM tb_order_detail WHERE order_id=@sample_order_id;
SELECT 'PLAN_REVENUE';
EXPLAIN ANALYZE SELECT IFNULL(SUM(actual_price), 0), COUNT(*)
FROM tb_order WHERE shop_id=7 AND status=6
AND order_completion_time >= NOW() - INTERVAL 7 DAY
AND order_completion_time < NOW() + INTERVAL 1 DAY;
SELECT 'PLAN_TREND';
EXPLAIN ANALYZE SELECT DATE_FORMAT(order_completion_time, '%Y-%m-%d'),
SUM(actual_price), COUNT(*) FROM tb_order
WHERE shop_id=7 AND status=6
AND order_completion_time >= NOW() - INTERVAL 7 DAY
AND order_completion_time < NOW() + INTERVAL 1 DAY
GROUP BY DATE_FORMAT(order_completion_time, '%Y-%m-%d');
SELECT 'PLAN_HOT_GOODS';
EXPLAIN ANALYZE SELECT od.goods_id, od.goods_name, SUM(od.number), SUM(od.subtotal)
FROM tb_order_detail od INNER JOIN tb_order o ON o.id=od.order_id
WHERE o.shop_id=7 AND o.status=6
AND o.order_completion_time >= NOW() - INTERVAL 30 DAY
AND o.order_completion_time < NOW() + INTERVAL 1 DAY
AND (od.is_deleted=0 OR od.is_deleted IS NULL)
GROUP BY od.goods_id, od.goods_name
ORDER BY SUM(od.number) DESC, SUM(od.subtotal) DESC LIMIT 10;
SQL
echo "phase643_index_plan_${MODE}=START"
"${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${PLAN_SQL}" mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"'
echo "phase643_index_plan_${MODE}=END"

WRITE_RESULTS=()
for run in 1 2 3 4 5; do
  read -r -d '' WRITE_SQL <<SQL || true
SET @write_start=NOW(6);
INSERT INTO tb_order
  (member_id, order_no, shopping_way, status, is_deleted, shop_id, shop_name,
   create_time, update_time, order_completion_time)
SELECT 1, CONCAT('WRITE643${MODE}${run}', LPAD(n, 8, '0')), 1, 6, 0,
       MOD(n, 50) + 1, 'Write Shop', NOW(), NOW(), NOW()
FROM (
  SELECT d0.n + 10*d1.n + 100*d2.n + 1000*d3.n AS n
  FROM
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
  CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
) write_values WHERE n < 2000;
INSERT INTO tb_order_detail
  (order_id, goods_id, goods_name, main_image, price, number, subtotal, is_deleted)
SELECT id, 1, 'Write Goods', 'qa.jpg', 1.00, 1, 1.00, 0
FROM tb_order WHERE order_no LIKE 'WRITE643${MODE}${run}%';
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @write_start, NOW(6))/1000, 3);
SQL
  WRITE_MS="$("${COMPOSE[@]}" exec -T -e QA_DB="${QA_DB}" -e QA_SQL="${WRITE_SQL}" mysql sh -c \
    'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$QA_DB" -e "$QA_SQL"' | tr -d '\r')"
  WRITE_RESULTS+=("${WRITE_MS}")
  echo "write_run_${run}_2000_orders_and_details_ms=${WRITE_MS}"
done
WRITE_MEDIAN="$(printf '%s\n' "${WRITE_RESULTS[@]}" | sort -n | sed -n '3p')"
echo "write_median_2000_orders_and_details_ms=${WRITE_MEDIAN}"

free -m | awk '/^Mem:/ {print "host_memory_available_mb=" $7}'
