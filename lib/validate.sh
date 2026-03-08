#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_VALIDATE_SH:-}" ]] && return 0
__LIB_VALIDATE_SH=1

validate_username() {
  local name="${1:-}"
  [[ "$name" =~ ^[a-z][-a-z0-9_]{0,31}$ ]]
}

validate_hostname() {
  local name="${1:-}"
  [[ "$name" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]
}

validate_domain() {
  local domain="${1:-}"
  [[ -z "$domain" ]] && return 0
  [[ "$domain" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]
}
