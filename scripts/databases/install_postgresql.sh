#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install PostgreSQL server package.
# Supports: debian, rhel, suse, arch
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

POSTGRES_PACKAGE=""
POSTGRES_SERVICE=""

show_preinstall_message() {
  info "This action will install PostgreSQL server package(s) and enable/start the PostgreSQL service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: database packages and service state will change."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  POSTGRES_PACKAGE="$(os_resolve_pkg postgresql_server)"
  POSTGRES_SERVICE="$(os_resolve_service postgresql)"

  if db_detect_conflicts "postgresql"; then
    db_print_conflict_risk "postgresql"
  fi
}

run_install() {
  pkg_refresh_index --reason "postgresql installation"
  pkg_install "$POSTGRES_PACKAGE"
  service_enable_now "$POSTGRES_SERVICE"
}

post_install() {
  db_print_install_summary "postgresql" "$POSTGRES_SERVICE"
  verify_section "Version checks"
  verify_command "psql --version" psql --version || true
  verify_section "Service status"
  verify_systemd_service "$POSTGRES_SERVICE" || true
}

main() {
  run_install_workflow \
    "PostgreSQL installation" \
    "Proceed with PostgreSQL installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
