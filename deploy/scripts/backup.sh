#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
set -a
source "${ENV_FILE}"
set +a
BACKUP_DIR="${BACKUP_DIR:-${DEPLOY_ROOT:-/opt/restaurant-saas}/backup}"
if [[ "${BACKUP_DIR}" == "/" || ${#BACKUP_DIR} -lt 10 ]]; then
  echo "Unsafe BACKUP_DIR: ${BACKUP_DIR}" >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="${BACKUP_DIR}/${STAMP}"
PARTIAL="${BACKUP_DIR}/.${STAMP}.partial"
umask 077
install -d -m 0700 "${BACKUP_DIR}"
exec 9>"${BACKUP_DIR}/.backup.lock"
flock -n 9 || {
  echo "Another backup is already running." >&2
  exit 1
}
trap 'rm -rf -- "${PARTIAL}"' ERR
install -d -m 0700 "${PARTIAL}"

"${COMPOSE[@]}" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" exec mysqldump --single-transaction --routines --triggers --events --no-tablespaces --set-gtid-purged=OFF -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
  | gzip -9 > "${PARTIAL}/mysql-${DB_NAME}.sql.gz"

"${COMPOSE[@]}" exec -T mongodb sh -c \
  'exec mongodump --quiet --archive --gzip --db "$MONGO_APP_DATABASE" --username "$MONGO_APP_USER" --password "$MONGO_APP_PASSWORD" --authenticationDatabase "$MONGO_APP_DATABASE"' \
  > "${PARTIAL}/mongodb-${MONGO_APP_DATABASE}.archive.gz"

"${COMPOSE[@]}" exec -T redis sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli BGSAVE' >/dev/null
for _ in {1..30}; do
  if [[ "$("${COMPOSE[@]}" exec -T redis sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli --raw INFO persistence' | tr -d '\r' | awk -F: '/rdb_bgsave_in_progress/{print $2}')" == "0" ]]; then
    break
  fi
  sleep 1
done
redis_persistence="$("${COMPOSE[@]}" exec -T redis sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli --raw INFO persistence' | tr -d '\r')"
grep -q '^rdb_bgsave_in_progress:0$' <<<"${redis_persistence}"
grep -q '^rdb_last_bgsave_status:ok$' <<<"${redis_persistence}"
"${COMPOSE[@]}" cp redis:/data/dump.rdb "${PARTIAL}/redis-dump.rdb"

test -s "${PARTIAL}/mysql-${DB_NAME}.sql.gz"
test -s "${PARTIAL}/mongodb-${MONGO_APP_DATABASE}.archive.gz"
test -s "${PARTIAL}/redis-dump.rdb"
gzip -t "${PARTIAL}/mysql-${DB_NAME}.sql.gz" "${PARTIAL}/mongodb-${MONGO_APP_DATABASE}.archive.gz"
(cd "${PARTIAL}" && sha256sum * > SHA256SUMS)
mv "${PARTIAL}" "${TARGET}"
find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime "+${RETENTION_DAYS}" -exec rm -rf -- {} +
echo "Backup completed: ${TARGET}"
