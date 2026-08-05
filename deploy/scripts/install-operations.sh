#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
DOCKER_DIR="${DEPLOY_ROOT}/docker"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi
if [[ "${DEPLOY_ROOT}" != /* || "${DEPLOY_ROOT}" == "/" || ${#DEPLOY_ROOT} -lt 10 ]]; then
  echo "Unsafe DEPLOY_ROOT: ${DEPLOY_ROOT}" >&2
  exit 1
fi
for file in \
  "${DOCKER_DIR}/scripts/backup.sh" \
  "${DOCKER_DIR}/scripts/health-check.sh" \
  "${DOCKER_DIR}/logrotate/restaurant-saas" \
  "${DOCKER_DIR}/systemd/restaurant-saas-backup.service" \
  "${DOCKER_DIR}/systemd/restaurant-saas-backup.timer" \
  "${DOCKER_DIR}/systemd/restaurant-saas-health.service" \
  "${DOCKER_DIR}/systemd/restaurant-saas-health.timer"; do
  [[ -f "${file}" ]] || {
    echo "Missing operations file: ${file}" >&2
    exit 1
  }
done

install -d -m 0700 "${DEPLOY_ROOT}/backup"
sed "s|__DEPLOY_ROOT__|${DEPLOY_ROOT}|g" "${DOCKER_DIR}/logrotate/restaurant-saas" > /etc/logrotate.d/restaurant-saas
chmod 0644 /etc/logrotate.d/restaurant-saas
for unit in "${DOCKER_DIR}"/systemd/restaurant-saas-*; do
  sed "s|__DEPLOY_ROOT__|${DEPLOY_ROOT}|g" "${unit}" > "/etc/systemd/system/$(basename "${unit}")"
  chmod 0644 "/etc/systemd/system/$(basename "${unit}")"
done

logrotate --debug /etc/logrotate.d/restaurant-saas >/dev/null
systemctl daemon-reload
systemctl enable --now restaurant-saas-backup.timer restaurant-saas-health.timer
echo "Operations installed: backup timer, health timer, logrotate."
