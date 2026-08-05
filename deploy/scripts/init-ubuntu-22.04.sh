#!/usr/bin/env bash
set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/restaurant-saas}"
SWAP_SIZE="${SWAP_SIZE:-2G}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl fail2ban gnupg git jq openssl ufw unattended-upgrades

if ! command -v docker >/dev/null 2>&1; then
  apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc || true
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker

timedatectl set-timezone Asia/Shanghai

install -d -m 0750 \
  "${DEPLOY_ROOT}/backend/source" \
  "${DEPLOY_ROOT}/docker" \
  "${DEPLOY_ROOT}/nginx/certbot/conf" \
  "${DEPLOY_ROOT}/nginx/certbot/www" \
  "${DEPLOY_ROOT}/mysql/data" \
  "${DEPLOY_ROOT}/redis/data" \
  "${DEPLOY_ROOT}/mongo/data" \
  "${DEPLOY_ROOT}/logs/backend" \
  "${DEPLOY_ROOT}/logs/nginx" \
  "${DEPLOY_ROOT}/backup"
chown -R 10001:10001 "${DEPLOY_ROOT}/logs/backend"

if ! swapon --show=NAME --noheadings | grep -q .; then
  fallocate -l "${SWAP_SIZE}" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

cat >/etc/sysctl.d/99-restaurant-saas.conf <<'EOF'
vm.swappiness=20
vm.vfs_cache_pressure=75
net.core.somaxconn=1024
EOF
sysctl --system >/dev/null

install -d -m 0755 /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/99-restaurant-saas-hardening.conf <<'EOF'
PermitEmptyPasswords no
MaxAuthTries 4
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
EOF

if [[ -s /root/.ssh/authorized_keys ]]; then
  cat >>/etc/ssh/sshd_config.d/99-restaurant-saas-hardening.conf <<'EOF'
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
fi

sshd -t
systemctl reload ssh

cat >/etc/fail2ban/jail.d/restaurant-saas-sshd.local <<'EOF'
[sshd]
enabled = true
maxretry = 4
findtime = 10m
bantime = 1h
EOF
systemctl enable --now fail2ban

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

systemctl enable --now unattended-upgrades

echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version)"
echo "Git: $(git --version)"
if command -v java >/dev/null 2>&1; then
  java -version 2>&1 | head -n 1
else
  echo "Host Java: not installed (backend uses the pinned JRE in Docker)."
fi
echo "Timezone: $(timedatectl show -p Timezone --value)"
echo "Swap: $(swapon --show=SIZE --noheadings | xargs)"
echo "Initialization complete: ${DEPLOY_ROOT}"
