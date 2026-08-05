#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
PROJECT_SOURCE="${PROJECT_SOURCE:-${DEPLOY_ROOT}/backend/source}"
DOCKER_DIR="${DEPLOY_ROOT}/docker"
ENV_FILE="${ENV_FILE:-${DOCKER_DIR}/.env.production}"
COMPOSE_FILE="${DOCKER_DIR}/docker-compose.production.yml"
MAVEN_BUILD_IMAGE="${MAVEN_BUILD_IMAGE:-maven:3.9.11-eclipse-temurin-8}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}; create it from .env.production.example and fill server-only secrets." >&2
  exit 1
fi
if [[ ! -f "${PROJECT_SOURCE}/pom.xml" ]]; then
  echo "Missing project source at ${PROJECT_SOURCE}." >&2
  exit 1
fi
if [[ -e "${PROJECT_SOURCE}/deploy/.env.production" ]]; then
  echo "Refusing deployment: merchant instance environment file must not exist inside project source." >&2
  exit 1
fi

install -d -m 0750 "${DOCKER_DIR}" "${DEPLOY_ROOT}/backup" "${DEPLOY_ROOT}/logs/backend" "${DEPLOY_ROOT}/logs/nginx"
cp -a "${PROJECT_SOURCE}/deploy/." "${DOCKER_DIR}/"
chmod 600 "${ENV_FILE}"
chown -R 10001:10001 "${DEPLOY_ROOT}/logs/backend"

if [[ "${BUILD_JAR:-true}" == "true" ]]; then
  docker run --rm \
    --memory=1g --cpus=1.5 \
    -v "${PROJECT_SOURCE}:/workspace" \
    -v restaurant-maven-cache:/root/.m2 \
    -w /workspace \
    "${MAVEN_BUILD_IMAGE}" \
    mvn -Pprod -pl siam-system/system-provider -am clean package -DskipTests
fi

if [[ ! -f "${PROJECT_SOURCE}/siam-system/system-provider/target/siam-server.jar" ]]; then
  echo "Production JAR was not generated." >&2
  exit 1
fi

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" config --quiet
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d --build

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

for attempt in $(seq 1 36); do
  if docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T mysql \
    sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin ping -h 127.0.0.1 -u"$MYSQL_USER" --silent' >/dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 36 ]]; then
    echo "MySQL did not become ready." >&2
    exit 1
  fi
  sleep 5
done

for migration in update.sql yuking_template.sql; do
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T mysql \
    sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" exec mysql -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
    < "${PROJECT_SOURCE}/sql/mysql/${migration}"
done

"${DOCKER_DIR}/scripts/verify-production.sh" "${ENV_FILE}"
"${DOCKER_DIR}/scripts/install-operations.sh"
