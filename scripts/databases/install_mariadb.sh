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

MARIADB_HARDEN_MODE="interactive"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hardening-mode)
        shift
        if [[ $# -eq 0 ]]; then
          error "Missing value for --hardening-mode (interactive|apply|skip)."
          return 1
        fi
        case "$1" in
          interactive|apply|skip) MARIADB_HARDEN_MODE="$1" ;;
          *) error "Invalid --hardening-mode value: $1"; return 1 ;;
        esac
        ;;
      --harden) MARIADB_HARDEN_MODE="apply" ;;
      --skip-harden) MARIADB_HARDEN_MODE="skip" ;;
      *)
        error "Unknown argument: $1"
        error "Usage: $0 [--hardening-mode interactive|apply|skip|--harden|--skip-harden]"
        return 1
        ;;
    esac
    shift
  done
}

show_preinstall_message() {
  info "This action will install MariaDB server and enable/start the MariaDB service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: database packages/service state will change; optional hardening can alter MariaDB system tables."
}

resolve_hardening_mode() {
  local mode="$1"
  if [[ "$mode" != "interactive" ]]; then
    printf '%s
' "$mode"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    info "Non-interactive session detected; optional MariaDB hardening will be skipped."
    printf 'skip
'
    return 0
  fi
  printf 'interactive
'
}

get_db_client() {
  if command -v mariadb >/dev/null 2>&1; then
    printf 'mariadb\n'; return 0
  fi
  if command -v mysql >/dev/null 2>&1; then
    printf 'mysql\n'; return 0
  fi
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

  [[ "$anonymous_users" == "0" ]] && success "Verification: anonymous users absent." || warn "Verification: anonymous users still present ($anonymous_users)."
  [[ "$remote_root" == "0" ]] && success "Verification: non-local root hosts absent." || warn "Verification: non-local root hosts still present ($remote_root)."
  [[ "$test_db" == "0" ]] && success "Verification: test database absent." || warn "Verification: test database still present ($test_db)."
}

harden_mariadb_if_requested() {
  local harden_mode="${1:?mode required}"
  if [[ "$harden_mode" != "apply" ]]; then
    info "MariaDB hardening skipped (optional)."
    return 0
  fi

  local client
  if ! client="$(get_db_client)"; then
    warn "MariaDB client binary not found; skipped hardening checks."
    return 0
  fi
  if ! db_can_auth_without_password "$client"; then
    warn "Cannot authenticate to MariaDB as local root without password; skipped scripted hardening."
    return 0
  fi
  if mariadb_is_hardened "$client"; then
    success "MariaDB hardening already satisfied; no changes needed."
    show_hardening_verification "$client"
    return 0
  fi

  info "Applying scripted MariaDB hardening."
  db_query "$client" "DELETE FROM mysql.user WHERE User='';"
  db_query "$client" "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');"
  db_query "$client" "DROP DATABASE IF EXISTS test;"
  db_query "$client" "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  db_query "$client" "FLUSH PRIVILEGES;"

  show_hardening_verification "$client"
  mariadb_is_hardened "$client" || { error "MariaDB hardening verification failed."; return 1; }
  success "MariaDB hardening applied successfully."
}

main() {
  parse_args "$@"

  need_root
  os_detect
  os_require_supported

  local pkg_name svc_name harden_mode
  pkg_name="$(os_resolve_pkg mariadb_server)"
  svc_name="$(os_resolve_service mariadb)"

  if db_detect_conflicts "mariadb"; then
    db_print_conflict_risk "mariadb"
  fi

  harden_mode="$(resolve_hardening_mode "$MARIADB_HARDEN_MODE")"
  if [[ "$harden_mode" == "interactive" ]]; then
    info "Optional hardening removes anonymous users, removes non-local root hosts, and drops the test database."
    if confirm_proceed "Proceed with optional MariaDB hardening?"; then
      harden_mode="apply"
    else
      harden_mode="skip"
      operator_aborted
    fi
  fi

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_refresh_index --reason "mariadb installation"
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  harden_mariadb_if_requested "$harden_mode"
  db_print_install_summary "mariadb" "$svc_name"

  success "MariaDB installation workflow completed."
}

main "$@"
