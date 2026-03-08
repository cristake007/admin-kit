#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install extrepo on Debian-family systems.
# Supports: debian
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib os
require_lib pkg
require_lib ui

show_preinstall_message() {
  info "This action will install the extrepo package."
  info "Prerequisites: root privileges on Debian/Ubuntu with package repository access."
  info "Key side effects: extrepo package will be installed."
}

main() {
  need_root
  os_detect
  if [[ "$OS_FAMILY" != "debian" ]]; then
    error "Extrepo is supported only on Debian/Ubuntu systems."
    return 1
  fi

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_refresh_index --reason "extrepo installation"
  pkg_install extrepo
  success "Extrepo installed."
}

main "$@"
