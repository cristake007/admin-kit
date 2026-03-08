#!/usr/bin/env bash
set -euo pipefail

__find_project_root() {
  local dir
  dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  dir="$(dirname -- "$dir")"
  while [[ "$dir" != "/" ]]; do
    if [[ -e "$dir/.project-root" || -d "$dir/.git" ]]; then
      printf '%s\n' "$dir"; return 0
    fi
    dir="$(dirname -- "$dir")"
  done
  return 1
}

if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(__find_project_root)" || {
    echo "ERROR: Could not locate project root (.project-root or .git)!" >&2
    exit 1
  }
  export PROJECT_ROOT
fi

require() {
  local rel="${1:?relative path required}"
  local path="$PROJECT_ROOT/$rel"
  [[ -r "$path" ]] || { echo "ERROR: Missing or unreadable: $path" >&2; return 1; }
  # shellcheck disable=SC1090
  source "$path"
}