#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Update package metadata and upgrade installed packages.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package updates

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib core
require_lib ui

show_preinstall_message() {
  info "This action will refresh package metadata and apply available system package upgrades."
  info "Prerequisites: root privileges and a working package repository network connection."
  info "Key side effects: installed packages may be upgraded to newer versions."
}

main() {
  need_root
  os_detect
  os_require_supported

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  info "Updating package index..."
  pkg_refresh_index --mode always --reason "system upgrade"

  info "Upgrading installed packages..."
  pkg_upgrade_system

  success "System update completed."
}

main "$@"
