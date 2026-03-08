#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_DB_SH:-}" ]] && return 0
__LIB_DB_SH=1

DB_CONFLICT_FOUND=0
DB_CONFLICT_LINES=()

_db_other_targets() {
  local target="${1:?target required}"
  case "$target" in
    mariadb) printf 'mysql\npostgresql\n' ;;
    mysql) printf 'mariadb\npostgresql\n' ;;
    postgresql) printf 'mariadb\nmysql\n' ;;
    *) return 1 ;;
  esac
}

_db_label() {
  local target="${1:?target required}"
  case "$target" in
    mariadb) printf 'MariaDB' ;;
    mysql) printf 'MySQL' ;;
    postgresql) printf 'PostgreSQL' ;;
    *) printf '%s' "$target" ;;
  esac
}

_db_pkg_candidates() {
  local target="${1:?target required}"
  case "$target" in
    mariadb) printf 'mariadb-server\nmariadb\n' ;;
    mysql) printf 'mysql-server\ndefault-mysql-server\nmysql-community-server\n' ;;
    postgresql) printf 'postgresql\npostgresql-server\n' ;;
    *) return 1 ;;
  esac
}

_db_service_candidates() {
  local target="${1:?target required}"
  case "$target" in
    mariadb) printf 'mariadb\n' ;;
    mysql) printf 'mysql\nmysqld\n' ;;
    postgresql) printf 'postgresql\n' ;;
    *) return 1 ;;
  esac
}

_db_installed_pkg_hits() {
  local target="${1:?target required}"
  local pkg=""
  local hits=()

  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    if pkg_is_installed "$pkg"; then
      hits+=("$pkg")
    fi
  done < <(_db_pkg_candidates "$target")

  printf '%s\n' "${hits[@]:-}" | awk 'NF' | awk '!seen[$0]++'
}

_db_active_service_hits() {
  local target="${1:?target required}"
  local service_name=""
  local hits=()

  if [[ "${SERVICE_BACKEND:-unknown}" != "systemd" ]]; then
    return 0
  fi

  while IFS= read -r service_name; do
    [[ -n "$service_name" ]] || continue
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
      hits+=("$service_name")
    fi
  done < <(_db_service_candidates "$target")

  printf '%s\n' "${hits[@]:-}" | awk 'NF' | awk '!seen[$0]++'
}

db_detect_conflicts() {
  local install_target="${1:?install target required}"
  local other_target=""

  DB_CONFLICT_FOUND=0
  DB_CONFLICT_LINES=()

  while IFS= read -r other_target; do
    [[ -n "$other_target" ]] || continue

    local pkg_hits=""
    local svc_hits=""
    pkg_hits="$(_db_installed_pkg_hits "$other_target" | paste -sd ', ' -)"
    svc_hits="$(_db_active_service_hits "$other_target" | paste -sd ', ' -)"

    if [[ -n "$pkg_hits" || -n "$svc_hits" ]]; then
      DB_CONFLICT_FOUND=1
      DB_CONFLICT_LINES+=("$(_db_label "$other_target"): installed packages [${pkg_hits:-none}], active services [${svc_hits:-none}]")
    fi
  done < <(_db_other_targets "$install_target")

  if [[ "$DB_CONFLICT_FOUND" -eq 1 ]]; then
    return 0
  fi
  return 1
}

db_print_conflict_risk() {
  local install_target="${1:?install target required}"

  warn "Detected another major database server on this host while preparing $(_db_label "$install_target")."
  warn "Coexistence risk: default ports can collide (MySQL/MariaDB: 3306, PostgreSQL: 5432), services may compete for resources, and operations become more complex."

  local line=""
  for line in "${DB_CONFLICT_LINES[@]}"; do
    warn "- $line"
  done
}

db_server_version() {
  local target="${1:?target required}"
  case "$target" in
    mariadb)
      if command -v mariadb >/dev/null 2>&1; then
        mariadb --version
      elif command -v mysql >/dev/null 2>&1; then
        mysql --version
      else
        printf 'unavailable (mariadb/mysql client not found)\n'
      fi
      ;;
    mysql)
      if command -v mysql >/dev/null 2>&1; then
        mysql --version
      else
        printf 'unavailable (mysql client not found)\n'
      fi
      ;;
    postgresql)
      if command -v psql >/dev/null 2>&1; then
        psql --version
      else
        printf 'unavailable (psql client not found)\n'
      fi
      ;;
    *)
      printf 'unknown target\n'
      ;;
  esac
}

db_print_install_summary() {
  local target="${1:?target required}"
  local service_name="${2:?service name required}"
  local version=""
  local service_state="inactive"
  local enable_state="disabled"

  version="$(db_server_version "$target" 2>/dev/null | head -n1)"

  if [[ "${SERVICE_BACKEND:-unknown}" == "systemd" ]]; then
    if service_exists "$service_name"; then
      if service_is_active "$service_name"; then
        service_state="active"
      fi
      if service_is_enabled "$service_name"; then
        enable_state="enabled"
      fi
    else
      service_state="missing"
      enable_state="missing"
    fi
  else
    service_state="unknown"
    enable_state="unknown"
  fi

  info "Verification summary for $(_db_label "$target"):"
  info "- Server version: ${version:-unknown}"
  info "- Service (${service_name}): ${service_state}, ${enable_state}"
}
