#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/service.sh"
trap err_trap ERR

need_sudo || exit 1

JAIL_DIR="/etc/fail2ban/jail.d"
JAIL_FILE="$JAIL_DIR/00-admin-kit-sshd.conf"

main() {
  echo_info "This installs Fail2Ban, configures a basic SSH jail, and enables the service."
  echo

  confirm "Proceed?" || { echo_info "Cancelled."; exit 0; }

  if apt_package_installed fail2ban; then
    echo_info "Fail2Ban already installed."
  else
    apt_update
    apt_install fail2ban python3-systemd
  fi

  sudo mkdir -p "$JAIL_DIR"

  if [[ -f "$JAIL_FILE" ]] && ! confirm "Fail2Ban jail exists at $JAIL_FILE. Overwrite?"; then
    echo_info "Keeping existing jail config."
  else
    sudo tee "$JAIL_FILE" >/dev/null <<'JAIL'
# Managed by admin-kit
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
backend  = systemd
JAIL
    echo_note "SSH jail saved to $JAIL_FILE"
  fi

  sudo fail2ban-client -t
  service_enable_now fail2ban
  service_status_line fail2ban
  sudo fail2ban-client status sshd || true
  echo_success "Fail2Ban installed and SSH jail enabled."
}

main "$@"
