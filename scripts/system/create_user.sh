#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Create a privileged admin user.
# Supports: linux with useradd/usermod
# Requires: root privileges
# Safe to rerun: yes
# Side effects: user and group membership changes

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib validate
require_lib ui
require_lib verify
require_lib install

TARGET_USERNAME=""
TARGET_EXISTS=0

show_message() {
  info "This action will create a local user and add it to sudo/wheel when available."
}

gather_input() {
  need_root
  TARGET_USERNAME="${1:-${TARGET_USERNAME:-}}"
  if [[ -z "$TARGET_USERNAME" ]]; then
    read -r -p "Enter username to create: " TARGET_USERNAME
  fi

  if ! validate_username "$TARGET_USERNAME"; then
    error "Invalid username format."
    return 1
  fi
}

show_current_state() {
  verify_section "Current user state"
  if id "$TARGET_USERNAME" >/dev/null 2>&1; then
    TARGET_EXISTS=1
    verify_item "user" "$TARGET_USERNAME already exists"
  else
    TARGET_EXISTS=0
    verify_item "user" "$TARGET_USERNAME does not exist"
  fi
}

change_needed() {
  [[ "$TARGET_EXISTS" -eq 0 ]]
}

safety_checks() {
  if getent group sudo >/dev/null 2>&1; then
    verify_item "privileged group" "sudo"
  elif getent group wheel >/dev/null 2>&1; then
    verify_item "privileged group" "wheel"
  else
    verify_warning "privileged group" "No sudo/wheel group found; user will be created without admin group assignment"
  fi
}

apply_change() {
  useradd -m -s /bin/bash "$TARGET_USERNAME"

  if getent group sudo >/dev/null 2>&1; then
    usermod -aG sudo "$TARGET_USERNAME"
  elif getent group wheel >/dev/null 2>&1; then
    usermod -aG wheel "$TARGET_USERNAME"
  fi
}

verify_result() {
  verify_section "Result"
  if id "$TARGET_USERNAME" >/dev/null 2>&1; then
    verify_item "user" "created: $TARGET_USERNAME"
    verify_item "groups" "$(id -nG "$TARGET_USERNAME")"
  else
    verify_warning "user" "creation failed for $TARGET_USERNAME"
    return 1
  fi
}

summary() {
  success "User provisioning completed for: $TARGET_USERNAME"
}

main() {
  TARGET_USERNAME="${1:-}"

  run_action_workflow \
    "Create privileged user" \
    "Proceed with creating user '$TARGET_USERNAME'?" \
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
