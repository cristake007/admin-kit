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
require_lib verify

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

show_preinstall_message() {
  local requested="${1:-<unset>}"
  info "This action will set the system timezone to '$requested'."
  info "Prerequisites: root privileges and a valid timezone from timedatectl list-timezones."
  info "Key side effects: system timezone configuration will change."
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
    verify_section "Effective settings"
    verify_item "timezone" "${existing_timezone:-<empty>}"
    return 0
  fi

  show_preinstall_message "$requested_timezone"
  info "Current timezone: $existing_timezone"
  info "Requested timezone: $requested_timezone"

  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  timedatectl set-timezone "$requested_timezone"

  local applied_timezone=""
  applied_timezone="$(current_timezone)"
  success "Timezone update completed."
  verify_section "Effective settings"
  verify_item "timezone" "${applied_timezone:-<empty>}"
}

main "$@"
