#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/service.sh"
trap err_trap ERR

SSHD_CFG="/etc/ssh/sshd_config"
SSHD_DIR="/etc/ssh/sshd_config.d"
DROPIN="$SSHD_DIR/99-admin-kit.conf"
BACKUP="$SSHD_CFG.admin-kit.bak"

main() {
  local sshd_test_err
  echo_info "This disables SSH root login by writing: $DROPIN"
  echo_info "It also creates a one-time backup: $BACKUP"
  echo_info "Make sure you have a sudo-capable non-root user first."

  confirm "Proceed?" || { echo_info "Cancelled."; exit 0; }

  if ! has_sudo_user; then
    echo_error "No non-root sudo user detected (groups: sudo/wheel)."
    exit 1
  fi

  need_sudo || exit 1

  if [[ -f "$DROPIN" ]] && grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' "$DROPIN"; then
    echo_success "Root SSH login already disabled."
    exit 0
  fi

  sudo mkdir -p "$SSHD_DIR"

  if [[ -f "$SSHD_CFG" && ! -f "$BACKUP" ]]; then
    sudo cp -a "$SSHD_CFG" "$BACKUP"
    echo_note "Backup created: $BACKUP"
  fi

  if ! grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CFG"; then
    printf "\nInclude /etc/ssh/sshd_config.d/*.conf\n" | sudo tee -a "$SSHD_CFG" >/dev/null
  fi

  sudo tee "$DROPIN" >/dev/null <<'CONF'
# Managed by admin-kit
PermitRootLogin no
CONF
  sudo chmod 0644 "$DROPIN"

  sshd_test_err="$(mktemp /tmp/sshd_test.err.XXXXXX)"
  if ! sudo sshd -t 2>"$sshd_test_err"; then
    echo_error "sshd config test failed:"
    cat "$sshd_test_err" >&2 || true
    sudo rm -f "$sshd_test_err" "$DROPIN" || true
    exit 1
  fi
  rm -f "$sshd_test_err" || true

  service_reload_or_restart ssh || service_reload_or_restart sshd
  echo_success "Root SSH login disabled via $DROPIN."
}

main "$@"
