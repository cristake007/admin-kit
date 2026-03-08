#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Create ILIAS working directories.
# Supports: linux
# Requires: root privileges
# Safe to rerun: yes
# Side effects: directory creation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib verify
require_lib ui
require_lib install

DIRS=(/var/www/ilias /var/www/ilias/data /var/log/ilias)

show_message() { info "This action will create standard ILIAS directories when missing."; }
gather_input() { need_root; }
show_current_state() {
  verify_section "Current directory state"
  local dir
  for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then verify_item "$dir" "present"; else verify_item "$dir" "missing"; fi
  done
}
change_needed() {
  local dir
  for dir in "${DIRS[@]}"; do [[ -d "$dir" ]] || return 0; done
  return 1
}
safety_checks() { info "Directories will be created with mkdir -p only."; }
apply_change() { local dir; for dir in "${DIRS[@]}"; do mkdir -p "$dir"; done; }
verify_result() { show_current_state; }
summary() { success "ILIAS directory setup completed."; }

main() {
  run_action_workflow \
    "Create ILIAS directories" \
    "Proceed with creating missing ILIAS directories?" \
    show_message gather_input show_current_state change_needed safety_checks apply_change verify_result summary
}

main "$@"
