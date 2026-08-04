#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${CONFIRM_RESTORE:-}" != "YES" ]]; then
  echo "Set CONFIRM_RESTORE=YES after confirming the target and maintenance window." >&2
  exit 1
fi

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
MYSQL_BACKUP="${MYSQL_BACKUP:-}"
MONGO_BACKUP="${MONGO_BACKUP:-}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
if [[ -z "${MYSQL_BACKUP}" && -z "${MONGO_BACKUP}" ]]; then
  echo "Set MYSQL_BACKUP and/or MONGO_BACKUP." >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ ! "${DB_NAME}" =~ ^[A-Za-z0-9_]+$ || ! "${MONGO_APP_DATABASE}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Unsafe database name." >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
"${COMPOSE[@]}" stop backend
trap '"${COMPOSE[@]}" start backend' EXIT

if [[ -n "${MYSQL_BACKUP}" ]]; then
  test -f "${MYSQL_BACKUP}"
  "${COMPOSE[@]}" exec -T -e MYSQL_PWD="${DB_ROOT_PASSWORD}" mysql \
    mysql -uroot -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_APP_USER}'@'%';"
  gzip -dc "${MYSQL_BACKUP}" | "${COMPOSE[@]}" exec -T -e MYSQL_PWD="${DB_PASSWORD}" mysql mysql -u"${DB_APP_USER}" "${DB_NAME}"
fi

if [[ -n "${MONGO_BACKUP}" ]]; then
  test -f "${MONGO_BACKUP}"
  "${COMPOSE[@]}" exec -T mongodb mongorestore --quiet --drop --archive --gzip \
    --username "${MONGO_APP_USER}" --password "${MONGO_APP_PASSWORD}" \
    --authenticationDatabase "${MONGO_APP_DATABASE}" < "${MONGO_BACKUP}"
fi

echo "Restore completed. Verify data before ending the maintenance window."
