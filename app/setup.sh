#!/usr/bin/env bash
set -euo pipefail

# Basic VPS bootstrap + stack startup for Debian/Ubuntu hosts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/app"
ENV_FILE="${APP_DIR}/.env"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

log() {
  printf '[setup] %s\n' "$1"
}

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script currently supports apt-based Linux distributions only." >&2
    exit 1
  fi
}

update_and_upgrade() {
  log "Updating apt package index"
  ${SUDO} apt-get update -y

  log "Upgrading installed packages"
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
}

install_security_tools() {
  log "Installing security baseline packages"
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-listchanges \
    ca-certificates \
    curl
}

configure_unattended_upgrades() {
  log "Enabling automatic security updates"
  ${SUDO} dpkg-reconfigure -f noninteractive unattended-upgrades

  local auto_conf="/etc/apt/apt.conf.d/20auto-upgrades"
  ${SUDO} tee "${auto_conf}" >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
}

configure_fail2ban() {
  log "Configuring fail2ban for SSH"
  ${SUDO} mkdir -p /etc/fail2ban
  ${SUDO} tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF

  ${SUDO} systemctl enable --now fail2ban
}

configure_ufw() {
  log "Configuring firewall (ufw)"
  ${SUDO} ufw default deny incoming
  ${SUDO} ufw default allow outgoing
  ${SUDO} ufw allow OpenSSH

  # Non-interactive enable is safe here because SSH is explicitly allowed above.
  ${SUDO} ufw --force enable
}

harden_sshd() {
  local sshd_conf="/etc/ssh/sshd_config"
  if [[ ! -f "${sshd_conf}" ]]; then
    log "Skipping SSH hardening (no ${sshd_conf} found)"
    return
  fi

  log "Applying conservative SSH hardening"
  ${SUDO} sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' "${sshd_conf}"
  ${SUDO} sed -i 's/^#\?MaxAuthTries .*/MaxAuthTries 3/' "${sshd_conf}"
  ${SUDO} sed -i 's/^#\?X11Forwarding .*/X11Forwarding no/' "${sshd_conf}"

  if ! grep -q '^PermitRootLogin ' "${sshd_conf}"; then
    echo 'PermitRootLogin prohibit-password' | ${SUDO} tee -a "${sshd_conf}" >/dev/null
  fi
  if ! grep -q '^MaxAuthTries ' "${sshd_conf}"; then
    echo 'MaxAuthTries 3' | ${SUDO} tee -a "${sshd_conf}" >/dev/null
  fi
  if ! grep -q '^X11Forwarding ' "${sshd_conf}"; then
    echo 'X11Forwarding no' | ${SUDO} tee -a "${sshd_conf}" >/dev/null
  fi

  ${SUDO} systemctl restart ssh || ${SUDO} systemctl restart sshd || true
}

install_docker_if_needed() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "Docker and docker compose already available"
    return
  fi

  log "Installing Docker Engine and Compose plugin"
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-plugin
  ${SUDO} systemctl enable --now docker

  if [[ -n "${SUDO}" ]]; then
    ${SUDO} usermod -aG docker "${USER}" || true
  fi
}

run_compose() {
  if [[ ! -f "${COMPOSE_FILE}" ]]; then
    echo "No compose file found at ${COMPOSE_FILE}" >&2
    exit 1
  fi

  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "No ${ENV_FILE} found. Create it first (example: cp ${APP_DIR}/.env.example ${ENV_FILE})."
    return 0
  fi

  log "Starting services with docker compose"
  (
    cd "${APP_DIR}"
    ${SUDO} docker compose --env-file .env up -d
  )
}

main() {
  require_apt
  update_and_upgrade
  install_security_tools
  configure_unattended_upgrades
  configure_fail2ban
  configure_ufw
  harden_sshd
  install_docker_if_needed
  run_compose
  log "Setup complete"
}

main "$@"
