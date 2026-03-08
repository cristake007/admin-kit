#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_ENV_SH:-}" ]] && return 0
__LIB_ENV_SH=1

ensure_env_file() {
  local env_file="${1:?env file path required}"

  if [[ -f "$env_file" ]]; then
    chmod 600 "$env_file"
    info "Environment file already exists: $env_file"
    return 0
  fi

  touch "$env_file"
  chmod 600 "$env_file"
  success "Created environment file: $env_file"
}

get_env_var() {
  local env_file="${1:?env file path required}"
  local key="${2:?key required}"

  [[ -f "$env_file" ]] || return 1
  awk -F= -v target="$key" '
    /^[[:space:]]*#/ { next }
    NF >= 2 {
      k=$1
      sub(/^[[:space:]]+/, "", k)
      sub(/[[:space:]]+$/, "", k)
      if (k == target) {
        v=substr($0, index($0, "=") + 1)
        sub(/^[[:space:]]+/, "", v)
        sub(/[[:space:]]+$/, "", v)
        print v
        exit 0
      }
    }
    END { exit 1 }
  ' "$env_file"
}

list_env_vars() {
  local env_file="${1:?env file path required}"
  [[ -f "$env_file" ]] || return 1

  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { print }
  ' "$env_file"
}

set_env_var() {
  local env_file="${1:?env file path required}"
  local key="${2:?key required}"
  local value="${3:-}"

  ensure_env_file "$env_file"

  local escaped_key
  escaped_key="$(printf '%s' "$key" | sed -e 's/[][\\.^$*+?{}|()]/\\&/g')"
  local escaped_value
  escaped_value="$(printf '%s' "$value" | sed -e 's/[\\&/]/\\&/g')"

  if grep -Eq "^[[:space:]]*${escaped_key}=" "$env_file"; then
    sed -i -E "s|^[[:space:]]*${escaped_key}=.*$|${key}=${escaped_value}|" "$env_file"
    info "Updated env var: $key"
  else
    printf '%s=%s\n' "$key" "$value" >> "$env_file"
    info "Added env var: $key"
  fi
}

unset_env_var() {
  local env_file="${1:?env file path required}"
  local key="${2:?key required}"

  [[ -f "$env_file" ]] || return 0

  local escaped_key
  escaped_key="$(printf '%s' "$key" | sed -e 's/[][\\.^$*+?{}|()]/\\&/g')"

  if grep -Eq "^[[:space:]]*${escaped_key}=" "$env_file"; then
    sed -i -E "/^[[:space:]]*${escaped_key}=/d" "$env_file"
    info "Removed env var: $key"
  else
    info "Env var not present: $key"
  fi
}
