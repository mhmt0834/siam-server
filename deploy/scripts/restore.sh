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

# shellcheck source=lib/env-file.sh
source "${DEPLOY_DIR}/scripts/lib/env-file.sh"
DB_NAME="$(env_file_value_or_default "${ENV_FILE}" DB_NAME "")"
MONGO_APP_DATABASE="$(env_file_value_or_default "${ENV_FILE}" MONGO_APP_DATABASE "")"

if [[ ! "${DB_NAME}" =~ ^[A-Za-z0-9_]+$ || ! "${MONGO_APP_DATABASE}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Unsafe database name." >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")

verify_backup() {
  local backup="$1"
  local directory checksum_file basename_value
  directory="$(dirname "${backup}")"
  checksum_file="${directory}/SHA256SUMS"
  basename_value="$(basename "${backup}")"
  if [[ -f "${checksum_file}" ]]; then
    (cd "${directory}" && grep -F "  ${basename_value}" SHA256SUMS | sha256sum -c -)
  fi
}

[[ -z "${MYSQL_BACKUP}" ]] || verify_backup "${MYSQL_BACKUP}"
[[ -z "${MONGO_BACKUP}" ]] || verify_backup "${MONGO_BACKUP}"
"${COMPOSE[@]}" stop backend
trap '"${COMPOSE[@]}" start backend' EXIT

if [[ -n "${MYSQL_BACKUP}" ]]; then
  test -f "${MYSQL_BACKUP}"
  "${COMPOSE[@]}" exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '\''$MYSQL_USER'\''@'\''%'\'';"'
  gzip -dc "${MYSQL_BACKUP}" | "${COMPOSE[@]}" exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql -u"$MYSQL_USER" "$MYSQL_DATABASE"'
fi

if [[ -n "${MONGO_BACKUP}" ]]; then
  test -f "${MONGO_BACKUP}"
  "${COMPOSE[@]}" exec -T mongodb sh -c \
    'exec mongorestore --quiet --drop --archive --gzip --username "$MONGO_APP_USER" --password "$MONGO_APP_PASSWORD" --authenticationDatabase "$MONGO_APP_DATABASE"' \
    < "${MONGO_BACKUP}"
fi

echo "Restore completed. Verify data before ending the maintenance window."
