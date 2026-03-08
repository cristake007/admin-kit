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
require_lib install

EXTREPO_PACKAGE="extrepo"

show_preinstall_message() {
  info "This action will install the extrepo package."
  info "Prerequisites: root privileges on Debian/Ubuntu with package repository access."
  info "Key side effects: extrepo package will be installed."
}

run_checks() {
  need_root
  os_detect
  if [[ "$OS_FAMILY" != "debian" ]]; then
    error "Extrepo is supported only on Debian/Ubuntu systems."
    return 1
  fi
}

run_install() {
  pkg_refresh_index --reason "extrepo installation"
  pkg_install "$EXTREPO_PACKAGE"
}

post_install() {
  if command -v extrepo >/dev/null 2>&1; then
    success "extrepo command is available."
  else
    warn "extrepo command not found in PATH after installation."
  fi
}

main() {
  run_install_workflow \
    "Extrepo installation" \
    "Proceed with extrepo installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
