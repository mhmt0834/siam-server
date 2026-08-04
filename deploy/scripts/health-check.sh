#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"
set -a
source "${ENV_FILE}"
set +a

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
FAILED=0

curl -fsS "https://${PUBLIC_DOMAIN}/healthz" >/dev/null || FAILED=1
"${COMPOSE[@]}" ps
"${COMPOSE[@]}" exec -T -e MYSQL_PWD="${DB_PASSWORD}" mysql mysqladmin ping -h 127.0.0.1 -u"${DB_APP_USER}" --silent || FAILED=1
"${COMPOSE[@]}" exec -T -e REDISCLI_AUTH="${REDIS_PASSWORD}" redis redis-cli ping | grep -q PONG || FAILED=1
"${COMPOSE[@]}" exec -T mongodb mongosh --quiet --username "${MONGO_APP_USER}" --password "${MONGO_APP_PASSWORD}" --authenticationDatabase "${MONGO_APP_DATABASE}" --eval 'quit(db.adminCommand({ping:1}).ok ? 0 : 2)' || FAILED=1

df -P / | awk 'NR==2 {print "disk_used=" $5}'
"${COMPOSE[@]}" stats --no-stream
exit "${FAILED}"
