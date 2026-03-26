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

is_fail2ban_operational() {
  service_is_active fail2ban || return 1
  sudo fail2ban-client ping >/dev/null 2>&1 || return 1
  sudo fail2ban-client status sshd >/dev/null 2>&1 || return 1
}

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
  sleep 1

  if ! is_fail2ban_operational; then
    echo_error "Fail2Ban is installed but not fully operational yet."
    service_status_line fail2ban
    echo_note "Recent fail2ban logs:"
    sudo journalctl -u fail2ban -n 20 --no-pager || true
    exit 1
  fi

  service_status_line fail2ban
  sudo fail2ban-client status sshd
  echo_success "Fail2Ban installed and SSH jail enabled."
}

main "$@"
