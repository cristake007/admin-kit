#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_CORE_SH:-}" ]] && return 0
__LIB_CORE_SH=1

find_project_root() {
  local dir
  dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -e "$dir/.project-root" || -d "$dir/.git" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname -- "$dir")"
  done
  return 1
}

if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(find_project_root)" || {
    echo "ERROR: Could not locate repository root." >&2
    exit 1
  }
  export PROJECT_ROOT
fi

require() {
  local rel_path="${1:?relative path is required}"
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
  "$full_path"
}
