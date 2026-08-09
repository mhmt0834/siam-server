#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
DEPLOY_DIR="${DEPLOY_ROOT}/docker"
PROJECT_SOURCE="${PROJECT_SOURCE:-${DEPLOY_ROOT}/backend/source}"
ENV_FILE="${ENV_FILE:-${DEPLOY_DIR}/.env.production}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
test -f "${ENV_FILE}"
test -f "${PROJECT_SOURCE}/pom.xml"
# shellcheck source=lib/env-file.sh
source "${DEPLOY_DIR}/scripts/lib/env-file.sh"
MAVEN_BUILD_IMAGE="${MAVEN_BUILD_IMAGE:-$(env_file_value_or_default "${ENV_FILE}" MAVEN_BUILD_IMAGE "maven:3.9.11-eclipse-temurin-8")}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(env_file_value_or_default "${ENV_FILE}" COMPOSE_PROJECT_NAME "yuking-restaurant-saas")}"

SHOP_COUNT_BEFORE="$(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM tb_shop"' | tr -d '\r')"
ORDER_COUNT_BEFORE="$(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM tb_order"' | tr -d '\r')"

docker run --rm --memory=1g --cpus=1.25 \
  --network "${COMPOSE_PROJECT_NAME}_data" \
  --env-file "${ENV_FILE}" \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_CONFIG_ADDITIONAL_LOCATION=file:/tmp/phase643-config/ \
  -e DB_HOST=mysql \
  -e REDIS_HOST=redis \
  -v "${PROJECT_SOURCE}:/workspace" \
  -v "${PROJECT_SOURCE}/siam-system/system-provider/src/main/resources/application-prod.yml.template:/tmp/phase643-config/application-prod.yml:ro" \
  -v "${DEPLOY_ROOT}/logs/backend:/app/logs" \
  -v restaurant-maven-cache:/root/.m2 \
  -w /workspace \
  "${MAVEN_BUILD_IMAGE}" sh -c '
    export DB_USERNAME="$DB_APP_USER"
    export SPRING_MAIL_HOST="${MAIL_HOST:-localhost}"
    export SPRING_MAIL_PORT="${MAIL_PORT:-25}"
    exec mvn -o -Pprod -pl siam-system/system-provider -am \
      -DskipTests=false -Dsurefire.failIfNoSpecifiedTests=false \
      -Dtest=Phase5FullChainIntegrationTest,MerchantBusinessStatisticsServiceTest,MerchantOrderControllerSecurityTest,MerchantOrderWebSocketHandlerTest,MerchantOrderWorkflowServiceTest,WechatPayV3ServiceTest,PaymentSecretCryptoTest,OSSUtilsTest \
      test
  '

SHOP_COUNT_AFTER="$(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM tb_shop"' | tr -d '\r')"
ORDER_COUNT_AFTER="$(docker compose --env-file "${ENV_FILE}" -f "${DEPLOY_DIR}/docker-compose.production.yml" exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_PASSWORD" mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM tb_order"' | tr -d '\r')"

[[ "${SHOP_COUNT_BEFORE}" == "${SHOP_COUNT_AFTER}" ]]
[[ "${ORDER_COUNT_BEFORE}" == "${ORDER_COUNT_AFTER}" ]]
echo "production_business_regression=OK shops=${SHOP_COUNT_AFTER} orders=${ORDER_COUNT_AFTER}"
