#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install PostgreSQL server.
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

show_preinstall_message() {
  info "This action will install PostgreSQL server packages and enable/start the PostgreSQL service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: database packages and service state will change."
}

main() {
  need_root
  os_detect
  os_require_supported

  local pkg_name
  local svc_name
  pkg_name="$(os_resolve_pkg postgresql_server)"
  svc_name="$(os_resolve_service postgresql)"

  if db_detect_conflicts "postgresql"; then
    db_print_conflict_risk "postgresql"
  fi

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_refresh_index --reason "postgresql installation"
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  db_print_install_summary "postgresql" "$svc_name"
  verify_section "Version checks"
  verify_command "psql --version" psql --version || true
  verify_section "Service status"
  verify_systemd_service "$svc_name" || true
  success "PostgreSQL installation completed."
}

main "$@"
