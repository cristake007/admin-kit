#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Disable SSH root login safely.
# Supports: linux with sshd and sshd -t
# Requires: root privileges
# Safe to rerun: yes
# Side effects: sshd config edits and reload

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib file
require_lib os
require_lib service
require_lib ui
require_lib verify
require_lib install

SSHD_CONFIG="/etc/ssh/sshd_config"
CURRENT_SETTING="<unset>"

ssh_root_setting() {
  awk '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*PermitRootLogin[[:space:]]+/ {print $2; found=1; exit}
    END {if (!found) print "<unset>"}
  ' "$SSHD_CONFIG"
}

show_message() {
  info "This action will set PermitRootLogin no in /etc/ssh/sshd_config."
}

gather_input() {
  need_root
  os_detect
  [[ -f "$SSHD_CONFIG" ]] || { error "SSH config not found: $SSHD_CONFIG"; return 1; }
}

show_current_state() {
  CURRENT_SETTING="$(ssh_root_setting)"
  verify_section "Current SSH root-login state"
  verify_item "PermitRootLogin" "$CURRENT_SETTING"
}

change_needed() {
  [[ "$CURRENT_SETTING" != "no" ]]
}

safety_checks() {
  verify_item "sshd config validation" "will run sshd -t after update"
}

apply_change() {
  backup_file "$SSHD_CONFIG"
  replace_or_add_key_value "$SSHD_CONFIG" "PermitRootLogin" "no"
  sshd -t -f "$SSHD_CONFIG"

  if service_exists ssh; then
    service_restart_if_present ssh
  elif service_exists sshd; then
    service_restart_if_present sshd
  else
    warn "SSH service unit not found; config changed but service not restarted."
  fi
}

verify_result() {
  verify_section "Result"
  verify_item "PermitRootLogin" "$(ssh_root_setting)"
}

summary() {
  success "Root SSH login disabled."
}

main() {
  run_action_workflow \
    "Disable SSH root login" \
    "Proceed with disabling SSH root login?" \
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
