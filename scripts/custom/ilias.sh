#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Run a safe baseline ILIAS dependency workflow.
# Supports: debian, rhel, suse
# Requires: root privileges
# Safe to rerun: yes
# Side effects: installs packages and creates directories

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib verify
require_lib ui
require_lib install

show_message() {
  info "This action runs the baseline ILIAS workflow: env file, directories, packages, Apache, PHP, and MariaDB."
}

gather_input() {
  need_root
}

show_current_state() {
  verify_section "Workflow steps"
  verify_item "1" "scripts/custom/env_file.sh"
  verify_item "2" "scripts/custom/create_directories.sh"
  verify_item "3" "scripts/system/common_packages.sh ilias"
  verify_item "4" "scripts/webserver/apache2.sh"
  verify_item "5" "scripts/developer/install_php.sh"
  verify_item "6" "scripts/databases/install_mariadb.sh"
}

change_needed() {
  return 0
}

safety_checks() {
  info "Each sub-step keeps its own confirmations and validation checks."
}

apply_change() {
  run_script scripts/custom/env_file.sh
  run_script scripts/custom/create_directories.sh
  run_script scripts/system/common_packages.sh ilias
  run_script scripts/webserver/apache2.sh
  run_script scripts/developer/install_php.sh
  run_script scripts/databases/install_mariadb.sh
}

verify_result() {
  verify_section "ILIAS workflow"
  verify_item "status" "baseline workflow executed"
}

summary() {
  success "ILIAS quick baseline workflow completed."
}

main() {
  run_action_workflow \
    "ILIAS baseline workflow" \
    "Proceed with baseline ILIAS workflow?" \
    show_message gather_input show_current_state change_needed safety_checks apply_change verify_result summary
}

main "$@"
