#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi
# shellcheck source=lib/env-file.sh
source "${DEPLOY_DIR}/scripts/lib/env-file.sh"
PUBLIC_DOMAIN="$(env_file_value_or_default "${ENV_FILE}" PUBLIC_DOMAIN "")"
NGINX_TEMPLATE="$(env_file_value_or_default "${ENV_FILE}" NGINX_TEMPLATE "api-http.conf.template")"
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-$(env_file_value_or_default "${ENV_FILE}" HEALTH_CHECK_URL "")}"
if [[ -z "${PUBLIC_DOMAIN}" && -z "${HEALTH_CHECK_URL}" ]]; then
  echo "PUBLIC_DOMAIN or HEALTH_CHECK_URL is required." >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
FAILED=0

if [[ -n "${HEALTH_CHECK_URL:-}" ]]; then
  curl -fsS --max-time 15 "${HEALTH_CHECK_URL}" >/dev/null || FAILED=1
elif [[ "${NGINX_TEMPLATE:-api-http.conf.template}" == "api-https.conf.template" ]]; then
  curl -fsS --max-time 15 "https://${PUBLIC_DOMAIN}/healthz" >/dev/null || FAILED=1
else
  curl -fsS --max-time 15 -H "Host: ${PUBLIC_DOMAIN}" "http://127.0.0.1/healthz" >/dev/null || FAILED=1
fi

while IFS='|' read -r service state health; do
  [[ -n "${service}" ]] || continue
  if [[ "${state}" != "running" || "${health}" != "healthy" ]]; then
    echo "Container unhealthy: ${service} state=${state} health=${health}" >&2
    FAILED=1
  fi
done < <("${COMPOSE[@]}" ps --format '{{.Service}}|{{.State}}|{{.Health}}')

"${COMPOSE[@]}" exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin ping -h 127.0.0.1 -u"$MYSQL_USER" --silent' || FAILED=1
"${COMPOSE[@]}" exec -T redis sh -c 'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli ping' | grep -q PONG || FAILED=1
"${COMPOSE[@]}" exec -T mongodb sh -c 'mongosh --quiet --username "$MONGO_APP_USER" --password "$MONGO_APP_PASSWORD" --authenticationDatabase "$MONGO_APP_DATABASE" --eval '\''quit(db.adminCommand({ping:1}).ok ? 0 : 2)'\''' || FAILED=1

DISK_USED="$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')"
echo "disk_used=${DISK_USED}%"
if (( DISK_USED >= 85 )); then
  echo "Disk usage is above the 85% threshold." >&2
  FAILED=1
fi
free -m | awk '/^Mem:/ {print "memory_available_mb=" $7}'
exit "${FAILED}"
