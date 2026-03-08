#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Disable SSH root login safely.
# Supports: linux with sshd and sshd -t
# Requires: root privileges
# Safe to rerun: yes
# Side effects: sshd config edits and reload

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib file
require_lib os
require_lib service

main() {
  need_root
  os_detect

  local cfg="/etc/ssh/sshd_config"
  if [[ ! -f "$cfg" ]]; then
    error "SSH config not found: $cfg"
    return 1
  fi

  backup_file "$cfg"
  replace_or_add_key_value "$cfg" "PermitRootLogin" "no"

  if ! sshd -t -f "$cfg"; then
    error "sshd config validation failed. Restore backup before continuing."
    return 1
  fi

  if service_exists ssh; then
    service_restart_if_present ssh
  elif service_exists sshd; then
    service_restart_if_present sshd
  else
    warn "SSH service unit not found; config changed but service not restarted."
  fi

  success "Root SSH login disabled."
}

main "$@"
