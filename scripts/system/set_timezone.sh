#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Configure timezone.
# Supports: linux with timedatectl
# Requires: root privileges
# Safe to rerun: yes
# Side effects: timezone configuration

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib ui

current_timezone() {
  timedatectl show --property=Timezone --value
}

timezone_exists() {
  local timezone="$1"
  timedatectl list-timezones | grep -Fxq "$timezone"
}

prompt_timezone() {
  local timezone_input=""
  while true; do
    read -r -p "Enter timezone (example: Europe/Bucharest): " timezone_input
    if [[ -z "$timezone_input" ]]; then
      warn "Timezone cannot be empty."
      continue
    fi

    if timezone_exists "$timezone_input"; then
      printf '%s\n' "$timezone_input"
      return 0
    fi

    warn "Unknown timezone: $timezone_input"
    info "Use 'timedatectl list-timezones' to see valid values."
  done
}

main() {
  need_root

  if ! command -v timedatectl >/dev/null 2>&1; then
    error "timedatectl is not available on this system."
    return 1
  fi

  local requested_timezone="${1:-}"
  if [[ -z "$requested_timezone" ]]; then
    requested_timezone="$(prompt_timezone)"
  fi

  if ! timezone_exists "$requested_timezone"; then
    error "Unknown timezone: $requested_timezone"
    return 1
  fi

  local existing_timezone=""
  existing_timezone="$(current_timezone)"

  if [[ "$existing_timezone" == "$requested_timezone" ]]; then
    info "Timezone is already set to $requested_timezone; no change needed."
    info "Current timezone: $existing_timezone"
    return 0
  fi

  info "Current timezone: $existing_timezone"
  info "Requested timezone: $requested_timezone"

  if ! confirm "Apply timezone change to '$requested_timezone'?"; then
    warn "Timezone change cancelled by user."
    return 0
  fi

  timedatectl set-timezone "$requested_timezone"

  local applied_timezone=""
  applied_timezone="$(current_timezone)"
  success "Timezone update completed."
  info "Verification: timedatectl reports timezone as '$applied_timezone'."
}

main "$@"
