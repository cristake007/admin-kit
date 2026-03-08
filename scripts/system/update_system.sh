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

main() {
  need_root
  os_detect
  os_require_supported

  info "Updating package index..."
  pkg_update_index

  info "Upgrading installed packages..."
  pkg_upgrade_system

  success "System update completed."
}

main "$@"
