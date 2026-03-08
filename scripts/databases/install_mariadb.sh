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

MARIADB_HARDEN_MODE="skip"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --harden)
        MARIADB_HARDEN_MODE="apply"
        ;;
      --skip-harden)
        MARIADB_HARDEN_MODE="skip"
        ;;
      *)
        error "Unknown argument: $1"
        error "Usage: $0 [--harden|--skip-harden]"
        return 1
        ;;
    esac
    shift
  done
}

get_db_client() {
  if command -v mariadb >/dev/null 2>&1; then
    printf 'mariadb\n'
    return 0
  fi
  if command -v mysql >/dev/null 2>&1; then
    printf 'mysql\n'
    return 0
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

  local anonymous_users
  local remote_root
  local test_db

  anonymous_users="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='';")"
  remote_root="$(db_query "$client" "SELECT COUNT(*) FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');")"
  test_db="$(db_query "$client" "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='test';")"

  [[ "$anonymous_users" == "0" && "$remote_root" == "0" && "$test_db" == "0" ]]
}

harden_mariadb_if_requested() {
  if [[ "$MARIADB_HARDEN_MODE" != "apply" ]]; then
    info "MariaDB hardening skipped (optional). Re-run with --harden to apply scripted checks/changes."
    return 0
  fi

  local client
  if ! client="$(get_db_client)"; then
    warn "MariaDB client binary not found; skipped hardening checks."
    return 0
  fi

  if ! db_can_auth_without_password "$client"; then
    warn "Cannot authenticate to MariaDB as local root without password; skipped scripted hardening."
    warn "Run a manual secure setup if your authentication model requires credentials."
    return 0
  fi

  if mariadb_is_hardened "$client"; then
    success "MariaDB hardening already satisfied; no changes needed."
    return 0
  fi

  info "Applying scripted MariaDB hardening (remove anonymous users, remote root, test DB)."
  db_query "$client" "DELETE FROM mysql.user WHERE User='';"
  db_query "$client" "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');"
  db_query "$client" "DROP DATABASE IF EXISTS test;"
  db_query "$client" "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  db_query "$client" "FLUSH PRIVILEGES;"

  if mariadb_is_hardened "$client"; then
    success "MariaDB hardening applied successfully."
  else
    error "MariaDB hardening verification failed. Review database state manually."
    return 1
  fi
}

main() {
  parse_args "$@"

  need_root
  os_detect
  os_require_supported

  local pkg_name
  local svc_name
  pkg_name="$(os_resolve_pkg mariadb_server)"
  svc_name="$(os_resolve_service mariadb)"

  pkg_update_index
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  harden_mariadb_if_requested

  success "MariaDB installation workflow completed."
}

main "$@"
