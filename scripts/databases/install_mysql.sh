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
MYSQL_SKIP_INSTALL=0

show_message() {
  info "This action will install MySQL server package(s) and enable/start the MySQL service."
}

run_prereq_checks() {
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
}

check_already_installed() {
  if pkg_is_installed "$MYSQL_PACKAGE" && service_exists "$MYSQL_SERVICE" && service_is_active "$MYSQL_SERVICE"; then
    MYSQL_SKIP_INSTALL=1
    info "MySQL package and active service already present."
  fi
}

check_conflicts() {
  if db_detect_conflicts "mysql"; then
    db_print_conflict_risk "mysql"
  fi
}

show_install_plan() {
  verify_item "package" "$MYSQL_PACKAGE"
  verify_item "service" "$MYSQL_SERVICE"
}

run_install() {
  if [[ "$MYSQL_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "mysql installation"
  pkg_install "$MYSQL_PACKAGE"
}

run_service_config() {
  service_enable_now "$MYSQL_SERVICE"
}

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "mysql --version" mysql --version || true
  verify_systemd_service "$MYSQL_SERVICE" || true
}

final_summary() {
  success "MySQL installation workflow finished."
}

main() {
  run_install_workflow \
    "MySQL installation" \
    "Proceed with MySQL installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
