#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Create a privileged admin user.
# Supports: linux with useradd/usermod
# Requires: root privileges
# Safe to rerun: yes
# Side effects: user and group membership changes

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib validate

main() {
  need_root

  local username="${1:-}"
  if [[ -z "$username" ]]; then
    read -r -p "Enter username to create: " username
  fi

  if ! validate_username "$username"; then
    error "Invalid username format."
    return 1
  fi

  if id "$username" >/dev/null 2>&1; then
    info "User already exists: $username"
  else
    useradd -m -s /bin/bash "$username"
    success "Created user: $username"
  fi

  if getent group sudo >/dev/null 2>&1; then
    usermod -aG sudo "$username"
  elif getent group wheel >/dev/null 2>&1; then
    usermod -aG wheel "$username"
  else
    warn "No sudo/wheel group found; skipped privilege group assignment."
  fi

  success "User provisioning completed for: $username"
}

main "$@"
