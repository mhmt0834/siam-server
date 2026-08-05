#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
DEPLOY_DIR="${DEPLOY_ROOT}/docker"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  exit 1
fi

COMPOSE=(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml")
LATEST_BACKUP="$(find "${DEPLOY_ROOT}/backup" -mindepth 1 -maxdepth 1 -type d -name '20*' -printf '%p\n' | sort | tail -n 1)"
MONGO_BACKUP="$(find "${LATEST_BACKUP}" -maxdepth 1 -name 'mongodb-*.archive.gz' -print -quit)"
REDIS_BACKUP="$(find "${LATEST_BACKUP}" -maxdepth 1 -name 'redis-dump.rdb' -print -quit)"
test -s "${MONGO_BACKUP}"
test -s "${REDIS_BACKUP}"
(cd "${LATEST_BACKUP}" && sha256sum -c SHA256SUMS >/dev/null)

STAMP="$(date +%H%M%S)"
MONGO_SRC="siam_qa_restore_src_${STAMP}"
MONGO_DST="siam_qa_restore_dst_${STAMP}"
REDIS_NAME="phase642-redis-restore-${STAMP}"
REDIS_VOLUME="phase642-redis-restore-${STAMP}"

cleanup() {
  set +e
  "${COMPOSE[@]}" exec -T -e QA_SRC="${MONGO_SRC}" -e QA_DST="${MONGO_DST}" mongodb sh -c \
    'mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval '\''db.getSiblingDB(process.env.QA_SRC).dropDatabase(); db.getSiblingDB(process.env.QA_DST).dropDatabase()'\''' >/dev/null 2>&1
  "${COMPOSE[@]}" exec -T mongodb rm -f /tmp/phase642.archive.gz >/dev/null 2>&1
  docker rm -f "${REDIS_NAME}" >/dev/null 2>&1
  docker volume rm "${REDIS_VOLUME}" >/dev/null 2>&1
}
trap cleanup EXIT

cat "${MONGO_BACKUP}" | "${COMPOSE[@]}" exec -T mongodb sh -c \
  'exec mongorestore --quiet --archive --gzip --dryRun --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'
echo "mongodb_scheduled_archive_dry_run=OK"

"${COMPOSE[@]}" exec -T -e QA_SRC="${MONGO_SRC}" mongodb sh -c \
  'mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval '\''db.getSiblingDB(process.env.QA_SRC).marker.insertOne({phase:"6.4.2",value:1})'\''' >/dev/null
"${COMPOSE[@]}" exec -T -e QA_SRC="${MONGO_SRC}" mongodb sh -c \
  'mongodump --quiet --archive=/tmp/phase642.archive.gz --gzip --db "$QA_SRC" --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'
"${COMPOSE[@]}" exec -T -e QA_SRC="${MONGO_SRC}" mongodb sh -c \
  'mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval '\''db.getSiblingDB(process.env.QA_SRC).dropDatabase()'\''' >/dev/null
"${COMPOSE[@]}" exec -T -e QA_SRC="${MONGO_SRC}" -e QA_DST="${MONGO_DST}" mongodb sh -c \
  'mongorestore --quiet --archive=/tmp/phase642.archive.gz --gzip --nsFrom "$QA_SRC.*" --nsTo "$QA_DST.*" --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin'
MONGO_COUNT="$("${COMPOSE[@]}" exec -T -e QA_DST="${MONGO_DST}" mongodb sh -c \
  'mongosh --quiet --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval '\''db.getSiblingDB(process.env.QA_DST).marker.countDocuments({phase:"6.4.2"})'\''' | tr -d '\r')"
[[ "${MONGO_COUNT}" == "1" ]]
echo "mongodb_isolated_restore=OK_documents_1"

REDIS_IMAGE="$(docker inspect "$("${COMPOSE[@]}" ps -q redis)" --format '{{.Config.Image}}')"
docker volume create "${REDIS_VOLUME}" >/dev/null
docker run --rm --network none -v "${LATEST_BACKUP}:/backup:ro" -v "${REDIS_VOLUME}:/data" "${REDIS_IMAGE}" \
  sh -c 'cp /backup/redis-dump.rdb /data/dump.rdb'
docker run -d --name "${REDIS_NAME}" --network none -v "${REDIS_VOLUME}:/data" "${REDIS_IMAGE}" \
  redis-server --appendonly no --save '' --protected-mode no >/dev/null
for _ in $(seq 1 20); do
  if docker exec "${REDIS_NAME}" redis-cli ping 2>/dev/null | grep -q PONG; then
    break
  fi
  sleep 1
done
REDIS_KEYS="$(docker exec "${REDIS_NAME}" redis-cli dbsize | tr -d '\r')"
[[ "${REDIS_KEYS}" =~ ^[0-9]+$ ]]
echo "redis_isolated_restore=OK_keys_${REDIS_KEYS}"

cleanup
trap - EXIT
echo "isolated_restore_cleanup=OK"
