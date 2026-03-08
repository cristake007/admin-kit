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
require_lib install

REQUESTED_TIMEZONE=""
CURRENT_TIMEZONE=""

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
  done
}

show_message() {
  info "This action will set the system timezone."
}

gather_input() {
  need_root
  command -v timedatectl >/dev/null 2>&1 || { error "timedatectl is not available on this system."; return 1; }

  REQUESTED_TIMEZONE="${1:-${REQUESTED_TIMEZONE:-}}"
  if [[ -z "$REQUESTED_TIMEZONE" ]]; then
    REQUESTED_TIMEZONE="$(prompt_timezone)"
  fi

  timezone_exists "$REQUESTED_TIMEZONE" || { error "Unknown timezone: $REQUESTED_TIMEZONE"; return 1; }
}

show_current_state() {
  CURRENT_TIMEZONE="$(timedatectl show --property=Timezone --value)"
  verify_section "Current timezone"
  verify_item "timezone" "$CURRENT_TIMEZONE"
}

change_needed() {
  [[ "$CURRENT_TIMEZONE" != "$REQUESTED_TIMEZONE" ]]
}

safety_checks() {
  verify_section "Requested change"
  verify_item "requested timezone" "$REQUESTED_TIMEZONE"
}

apply_change() {
  timedatectl set-timezone "$REQUESTED_TIMEZONE"
}

verify_result() {
  verify_section "Result"
  verify_item "timezone" "$(timedatectl show --property=Timezone --value)"
}

summary() {
  success "Timezone update completed."
}

main() {
  REQUESTED_TIMEZONE="${1:-}"

  run_action_workflow \
    "Set timezone" \
    "Proceed with timezone change to '$REQUESTED_TIMEZONE'?" \
    show_message \
    gather_input \
    show_current_state \
    change_needed \
    safety_checks \
    apply_change \
    verify_result \
    summary
}

main "$@"
