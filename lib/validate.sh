#!/usr/bin/env bash

[[ -n "${__LIB_VALIDATE_SH:-}" ]] && return 0
__LIB_VALIDATE_SH=1

validate_non_empty() {
  [[ -n "${1:-}" ]]
}

validate_username() {
  local username="$1"
  [[ "$username" =~ ^[a-z][-a-z0-9_]{0,31}$ ]]
}

validate_hostname_label() {
  local hn="$1"
  [[ "$hn" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]
}

validate_domain() {
  local dn="$1"
  [[ -z "$dn" || "$dn" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]
}

validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

validate_timezone() {
  local tz="$1"
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl list-timezones | grep -Fxq "$tz"
  else
    [[ "$tz" =~ ^[A-Za-z_]+/[A-Za-z0-9_+.-]+$ ]]
  fi
}
