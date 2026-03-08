#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_FILE_SH:-}" ]] && return 0
__LIB_FILE_SH=1

backup_file() {
  local file_path="${1:?file path required}"
  [[ -f "$file_path" ]] || return 0
  local backup_path="${file_path}.bak.$(date +%Y%m%d%H%M%S)"
  cp -a "$file_path" "$backup_path"
  info "Backup created: $backup_path"
}

ensure_line_once() {
  local file_path="${1:?file path required}"
  local line="${2:?line required}"
  touch "$file_path"
  if ! grep -Fxq "$line" "$file_path"; then
    printf '%s\n' "$line" >> "$file_path"
  fi
}

replace_or_add_key_value() {
  local file_path="${1:?file path required}"
  local key="${2:?key required}"
  local value="${3:?value required}"

  local escaped_key
  escaped_key="$(printf '%s' "$key" | sed -e 's/[][\\.^$*+?{}|()]/\\&/g')"

  touch "$file_path"
  if grep -Eq "^[#[:space:]]*${escaped_key}([[:space:]]+|=)" "$file_path"; then
    sed -i -E "s|^[#[:space:]]*${escaped_key}([[:space:]]+|=).*$|${key} ${value}|" "$file_path"
  else
    printf '%s %s\n' "$key" "$value" >> "$file_path"
  fi
}
