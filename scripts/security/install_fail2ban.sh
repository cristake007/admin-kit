#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

JAIL_DIR="/etc/fail2ban/jail.d"
JAIL_FILE="$JAIL_DIR/00-admin-kit-sshd.conf"

main() {
  echo_info "This installs Fail2Ban, writes a basic SSH jail (systemd backend),"
  echo_info "validates the config, and enables the service."
  echo

  if ! confirm "Proceed?"; then
    echo_info "Cancelled."
    exit 0
  fi

  # Skip reinstall if already installed
  if apt_is_installed fail2ban; then
    echo_info "Fail2Ban already installed. Skipping package installation."
  else
    echo_note "Installing fail2ban (+ systemd backend deps)..."
    apt_update
    apt_install fail2ban python3-systemd
  fi

  # Ensure jail directory exists
  sudo mkdir -p "$JAIL_DIR"

  # Overwrite prompt if jail file already exists
  if [[ -f "$JAIL_FILE" ]]; then
    if confirm "Fail2Ban jail exists at $JAIL_FILE. Overwrite?"; then
      echo_note "Overwriting SSH jail (systemd backend) at $JAIL_FILE"
      sudo tee "$JAIL_FILE" >/dev/null <<'EOF'
# Managed by admin-kit
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
backend  = systemd
EOF
    else
      echo_info "Keeping existing jail config."
    fi
  else
    echo_note "Writing SSH jail (systemd backend) to $JAIL_FILE"
    sudo tee "$JAIL_FILE" >/dev/null <<'EOF'
# Managed by admin-kit
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
backend  = systemd
EOF
  fi

  # Validate and enable/start service
  echo_note "Validating config (fail2ban-client -t)..."
  sudo fail2ban-client -t

  echo_note "Enabling and starting fail2ban..."
  sudo systemctl enable --now fail2ban

  # Small readiness wait to avoid socket race on first status call
  for i in {1..20}; do
    if sudo systemctl is-active --quiet fail2ban && \
       { sudo test -S /var/run/fail2ban/fail2ban.sock || sudo fail2ban-client ping >/dev/null 2>&1; }; then
      break
    fi
    sleep 0.5
  done

  echo_info "Fail2Ban status:"
  sudo fail2ban-client status || true
  echo_info "SSHD jail status:"
  sudo fail2ban-client status sshd || true

  echo_success "Fail2Ban installed and SSH jail enabled."
}

main
