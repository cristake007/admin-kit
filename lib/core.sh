#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_CORE_SH:-}" ]] && return 0
__LIB_CORE_SH=1

require() {
  local rel_path="${1:?relative path is required}"
  [[ -n "${PROJECT_ROOT:-}" ]] || {
    echo "ERROR: PROJECT_ROOT is not set. Source scripts/bootstrap.sh before requiring modules." >&2
    return 1
  }

  local full_path="$PROJECT_ROOT/$rel_path"
  [[ -r "$full_path" ]] || {
    echo "ERROR: Missing module: $full_path" >&2
    return 1
  }
  # shellcheck disable=SC1090
  source "$full_path"
}

require_lib() {
  require "lib/$1.sh"
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    error "Please run this script as root (or with sudo)."
    return 1
  fi
}

run_script() {
  local rel_path="${1:?script path required}"
  local full_path="$PROJECT_ROOT/$rel_path"
  [[ -x "$full_path" ]] || chmod +x "$full_path"
  "$full_path" "${@:2}"
}
