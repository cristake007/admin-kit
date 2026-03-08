#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install MySQL-compatible server package.
# Supports: debian, rhel, suse
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package install and service enablement

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib service
require_lib core
require_lib db
require_lib ui

show_preinstall_message() {
  info "This action will install MySQL server packages and enable/start the MySQL service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: database packages and service state will change."
}

main() {
  need_root
  os_detect
  os_require_supported

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "MySQL installer is unsupported on arch in this toolkit. Use MariaDB instead."
    return 1
  fi

  local pkg_name
  local svc_name
  pkg_name="$(os_resolve_pkg mysql_server)" || {
    error "MySQL package is unsupported on distro family: $OS_FAMILY"
    return 1
  }
  svc_name="$(os_resolve_service mysql)"

  if db_detect_conflicts "mysql"; then
    db_print_conflict_risk "mysql"
  fi

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_refresh_index --reason "mysql installation"
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  db_print_install_summary "mysql" "$svc_name"
  success "MySQL installation completed."
}

main "$@"
