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
POSTGRES_SKIP_INSTALL=0

show_message() {
  info "This action will install PostgreSQL server package(s) and enable/start the PostgreSQL service."
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported
  POSTGRES_PACKAGE="$(os_resolve_pkg postgresql_server)"
  POSTGRES_SERVICE="$(os_resolve_service postgresql)"
}

check_already_installed() {
  if pkg_is_installed "$POSTGRES_PACKAGE" && service_exists "$POSTGRES_SERVICE" && service_is_active "$POSTGRES_SERVICE"; then
    POSTGRES_SKIP_INSTALL=1
    info "PostgreSQL package and active service already present."
  fi
}

check_conflicts() {
  if db_detect_conflicts "postgresql"; then
    db_print_conflict_risk "postgresql"
  fi
}

show_install_plan() {
  verify_item "package" "$POSTGRES_PACKAGE"
  verify_item "service" "$POSTGRES_SERVICE"
}

run_install() {
  if [[ "$POSTGRES_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "postgresql installation"
  pkg_install "$POSTGRES_PACKAGE"
}

run_service_config() { service_enable_now "$POSTGRES_SERVICE"; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "psql --version" psql --version || true
  verify_systemd_service "$POSTGRES_SERVICE" || true
}

final_summary() { success "PostgreSQL installation workflow finished."; }

main() {
  run_install_workflow \
    "PostgreSQL installation" \
    "Proceed with PostgreSQL installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
