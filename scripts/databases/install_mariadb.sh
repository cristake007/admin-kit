#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install MariaDB server with optional safe hardening.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package install, service enablement, optional DB security changes

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

MARIADB_HARDEN_MODE="interactive"
MARIADB_PACKAGE=""
MARIADB_SERVICE=""
MARIADB_SKIP_INSTALL=0

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hardening-mode)
        shift
        case "${1:-}" in
          interactive|apply|skip) MARIADB_HARDEN_MODE="$1" ;;
          *) error "Invalid --hardening-mode value: ${1:-<empty>}"; return 1 ;;
        esac
        ;;
      --harden) MARIADB_HARDEN_MODE="apply" ;;
      --skip-harden) MARIADB_HARDEN_MODE="skip" ;;
      *) error "Unknown argument: $1"; return 1 ;;
    esac
    shift
  done
}

resolve_hardening_mode() {
  local mode="$1"
  if [[ "$mode" != "interactive" ]]; then
    printf '%s\n' "$mode"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    printf 'skip\n'
    return 0
  fi
  printf 'interactive\n'
}

get_db_client() {
  if command -v mariadb >/dev/null 2>&1; then printf 'mariadb\n'; return 0; fi
  if command -v mysql >/dev/null 2>&1; then printf 'mysql\n'; return 0; fi
  return 1
}

db_query() {
  local client="${1:?client required}"
  local query="${2:?query required}"
  "$client" --batch --skip-column-names -e "$query"
}

db_can_auth_without_password() {
  local client="${1:?client required}"
  "$client" --batch --skip-column-names -e 'SELECT 1;' >/dev/null 2>&1
}

mariadb_is_hardened() {
  local client="${1:?client required}"
  local anonymous_users remote_root test_db
  anonymous_users="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='';")"
  remote_root="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');")"
  test_db="$(db_query "$client" "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='test';")"
  [[ "$anonymous_users" == "0" && "$remote_root" == "0" && "$test_db" == "0" ]]
}

show_hardening_verification() {
  local client="${1:?client required}"
  local anonymous_users remote_root test_db
  anonymous_users="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='';")"
  remote_root="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');")"
  test_db="$(db_query "$client" "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='test';")"

  [[ "$anonymous_users" == "0" ]] && success "Hardening verification: anonymous users absent." || warn "Hardening verification: anonymous users still present ($anonymous_users)."
  [[ "$remote_root" == "0" ]] && success "Hardening verification: non-local root hosts absent." || warn "Hardening verification: non-local root hosts still present ($remote_root)."
  [[ "$test_db" == "0" ]] && success "Hardening verification: test database absent." || warn "Hardening verification: test database still present ($test_db)."
}

harden_mariadb_if_requested() {
  if [[ "$MARIADB_HARDEN_MODE" != "apply" ]]; then
    info "MariaDB hardening skipped (optional)."
    return 0
  fi

  local client
  client="$(get_db_client)" || { warn "MariaDB client binary not found; skipped scripted hardening checks."; return 0; }
  db_can_auth_without_password "$client" || { warn "Cannot authenticate to MariaDB as local root without password; skipped scripted hardening."; return 0; }

  if mariadb_is_hardened "$client"; then
    success "MariaDB hardening already satisfied; no changes needed."
    show_hardening_verification "$client"
    return 0
  fi

  db_query "$client" "DELETE FROM mysql.user WHERE User='';"
  db_query "$client" "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');"
  db_query "$client" "DROP DATABASE IF EXISTS test;"
  db_query "$client" "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  db_query "$client" "FLUSH PRIVILEGES;"

  show_hardening_verification "$client"
  mariadb_is_hardened "$client" || { error "MariaDB hardening verification failed."; return 1; }
}

show_message() {
  info "This action will install MariaDB server and enable/start its service."
  info "Optional hardening can remove anonymous users, remove remote root hosts, and drop test database."
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported

  MARIADB_PACKAGE="$(os_resolve_pkg mariadb_server)"
  MARIADB_SERVICE="$(os_resolve_service mariadb)"

  local harden_mode
  harden_mode="$(resolve_hardening_mode "$MARIADB_HARDEN_MODE")"
  if [[ "$harden_mode" == "interactive" ]]; then
    if confirm_proceed "Proceed with optional MariaDB hardening?"; then
      MARIADB_HARDEN_MODE="apply"
    else
      MARIADB_HARDEN_MODE="skip"
    fi
  else
    MARIADB_HARDEN_MODE="$harden_mode"
  fi
}

check_already_installed() {
  if pkg_is_installed "$MARIADB_PACKAGE" && service_exists "$MARIADB_SERVICE" && service_is_active "$MARIADB_SERVICE"; then
    MARIADB_SKIP_INSTALL=1
    info "MariaDB package and active service already present."
  fi
}

check_conflicts() {
  if db_detect_conflicts "mariadb"; then
    db_print_conflict_risk "mariadb"
  fi
}

show_install_plan() {
  verify_item "package" "$MARIADB_PACKAGE"
  verify_item "service" "$MARIADB_SERVICE"
  verify_item "hardening mode" "$MARIADB_HARDEN_MODE"
}

run_install() {
  if [[ "$MARIADB_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "mariadb installation"
  pkg_install "$MARIADB_PACKAGE"
}

run_service_config() {
  service_enable_now "$MARIADB_SERVICE"
  harden_mariadb_if_requested
}

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "mariadb --version" mariadb --version || verify_command "mysql --version" mysql --version || true
  verify_systemd_service "$MARIADB_SERVICE" || true
}

final_summary() {
  success "MariaDB installation workflow finished."
}

main() {
  parse_args "$@"

  run_install_workflow \
    "MariaDB installation" \
    "Proceed with MariaDB installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
