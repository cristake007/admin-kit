#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Ensure project .env file exists with secure permissions.
# Supports: linux
# Requires: write access to repo root
# Safe to rerun: yes
# Side effects: creates or normalizes .env permissions

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib env
require_lib verify
require_lib ui
require_lib install

ENV_FILE="$PROJECT_ROOT/.env"

show_message() { info "This action ensures the project .env file exists with mode 600."; }
gather_input() { :; }
show_current_state() {
  verify_section "Current env-file state"
  if [[ -f "$ENV_FILE" ]]; then
    verify_item "path" "$ENV_FILE exists"
    verify_item "mode" "$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo unknown)"
  else
    verify_item "path" "$ENV_FILE missing"
  fi
}
change_needed() {
  [[ ! -f "$ENV_FILE" ]] && return 0
  [[ "$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo '')" != "600" ]]
}
safety_checks() { info "Only file existence and permission bits are managed."; }
apply_change() { ensure_env_file "$ENV_FILE"; }
verify_result() { show_current_state; }
summary() { success "Environment file state is now compliant."; }

main() {
  run_action_workflow \
    "Ensure env file" \
    "Proceed with ensuring .env file state?" \
    show_message gather_input show_current_state change_needed safety_checks apply_change verify_result summary
}

main "$@"
