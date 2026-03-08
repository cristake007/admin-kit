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
require_lib verify
require_lib install

MYSQL_PACKAGE=""
MYSQL_SERVICE=""

show_preinstall_message() {
  info "This action will install MySQL server packages and enable/start the MySQL service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: database packages and service state will change."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "MySQL installer is unsupported on arch in this toolkit. Use MariaDB instead."
    return 1
  fi

  MYSQL_PACKAGE="$(os_resolve_pkg mysql_server)" || {
    error "MySQL package is unsupported on distro family: $OS_FAMILY"
    return 1
  }
  MYSQL_SERVICE="$(os_resolve_service mysql)"

  if db_detect_conflicts "mysql"; then
    db_print_conflict_risk "mysql"
  fi
}

run_install() {
  pkg_refresh_index --reason "mysql installation"
  pkg_install "$MYSQL_PACKAGE"
  service_enable_now "$MYSQL_SERVICE"
}

post_install() {
  db_print_install_summary "mysql" "$MYSQL_SERVICE"
  verify_section "Version checks"
  verify_command "mysql --version" mysql --version || true
  verify_section "Service status"
  verify_systemd_service "$MYSQL_SERVICE" || true
}

main() {
  run_install_workflow \
    "MySQL installation" \
    "Proceed with MySQL installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
