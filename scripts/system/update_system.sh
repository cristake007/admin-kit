#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Update package metadata and upgrade installed packages.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package updates

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib core
require_lib ui
require_lib verify
require_lib install

show_message() {
  info "This action will refresh package metadata and apply available system package upgrades."
  info "Key side effects: installed packages may be upgraded to newer versions."
}

gather_input() {
  need_root
}

show_current_state() {
  os_detect
  os_require_supported
  verify_section "Current system"
  verify_item "OS family" "$OS_FAMILY"
  verify_item "Package backend" "$PKG_BACKEND"
}

change_needed() {
  return 0
}

safety_checks() {
  info "Safety check: package upgrade can restart services and alter package versions."
}

apply_change() {
  pkg_refresh_index --mode always --reason "system upgrade"
  pkg_upgrade_system
}

verify_result() {
  verify_section "Result"
  verify_item "Upgrade command" "completed"
}

summary() {
  success "System update completed."
}

main() {
  run_action_workflow \
    "System update" \
    "Proceed with system package upgrade?" \
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
