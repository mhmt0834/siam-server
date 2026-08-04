#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/restaurant-saas}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
if [[ "${BACKUP_DIR}" == "/" || ${#BACKUP_DIR} -lt 10 ]]; then
  echo "Unsafe BACKUP_DIR: ${BACKUP_DIR}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="${BACKUP_DIR}/${STAMP}"
mkdir -p "${TARGET}"

"${COMPOSE[@]}" exec -T -e MYSQL_PWD="${DB_PASSWORD}" mysql \
  mysqldump --single-transaction --routines --triggers --events \
  --set-gtid-purged=OFF -u"${DB_APP_USER}" "${DB_NAME}" \
  | gzip -9 > "${TARGET}/mysql-${DB_NAME}.sql.gz"

"${COMPOSE[@]}" exec -T mongodb \
  mongodump --quiet --archive --gzip --db "${MONGO_APP_DATABASE}" \
  --username "${MONGO_APP_USER}" --password "${MONGO_APP_PASSWORD}" \
  --authenticationDatabase "${MONGO_APP_DATABASE}" \
  > "${TARGET}/mongodb-${MONGO_APP_DATABASE}.archive.gz"

"${COMPOSE[@]}" exec -T -e REDISCLI_AUTH="${REDIS_PASSWORD}" redis redis-cli BGSAVE >/dev/null
for _ in {1..30}; do
  if [[ "$("${COMPOSE[@]}" exec -T -e REDISCLI_AUTH="${REDIS_PASSWORD}" redis redis-cli --raw INFO persistence | tr -d '\r' | awk -F: '/rdb_bgsave_in_progress/{print $2}')" == "0" ]]; then
    break
  fi
  sleep 1
done
"${COMPOSE[@]}" cp redis:/data/dump.rdb "${TARGET}/redis-dump.rdb"

sha256sum "${TARGET}"/* > "${TARGET}/SHA256SUMS"
find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime "+${RETENTION_DAYS}" -exec rm -rf -- {} +
echo "Backup completed: ${TARGET}"
