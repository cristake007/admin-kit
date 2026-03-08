#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Set system hostname and keep /etc/hosts in sync.
# Supports: linux with hostnamectl
# Requires: root privileges
# Safe to rerun: yes
# Side effects: hostname and /etc/hosts changes

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib validate
require_lib file
require_lib ui
require_lib verify
require_lib install

SHORT_NAME=""
DOMAIN_NAME=""
TARGET_FQDN=""
CURRENT_STATIC=""

show_message() {
  info "This action will set the static hostname and update /etc/hosts entry 127.0.1.1."
}

gather_input() {
  need_root

  if [[ -z "$SHORT_NAME" ]]; then
    read -r -p "Enter short hostname: " SHORT_NAME
  fi

  if [[ -z "$DOMAIN_NAME" ]]; then
    info "Domain is optional. Leave blank for short hostname only."
    read -r -p "Enter domain (optional): " DOMAIN_NAME
  fi

  validate_hostname "$SHORT_NAME" || { error "Invalid short hostname: $SHORT_NAME"; return 1; }
  validate_domain "$DOMAIN_NAME" || { error "Invalid domain: $DOMAIN_NAME"; return 1; }

  TARGET_FQDN="$SHORT_NAME"
  if [[ -n "$DOMAIN_NAME" ]]; then
    TARGET_FQDN="$SHORT_NAME.$DOMAIN_NAME"
  fi
}

show_current_state() {
  CURRENT_STATIC="$(hostnamectl --static 2>/dev/null || true)"
  verify_section "Current hostname state"
  verify_item "hostnamectl --static" "${CURRENT_STATIC:-<empty>}"
}

change_needed() {
  [[ "$CURRENT_STATIC" != "$TARGET_FQDN" ]]
}

safety_checks() {
  verify_section "Requested change"
  verify_item "target hostname" "$TARGET_FQDN"
  verify_item "/etc/hosts backup" "will be created before update"
}

apply_change() {
  hostnamectl set-hostname "$TARGET_FQDN"
  backup_file /etc/hosts
  replace_or_add_key_value /etc/hosts "127.0.1.1" "$TARGET_FQDN $SHORT_NAME"
}

verify_result() {
  verify_section "Result"
  verify_item "hostnamectl --static" "$(hostnamectl --static 2>/dev/null || true)"
  verify_item "hostnamectl --fqdn" "$(hostnamectl --fqdn 2>/dev/null || true)"
}

summary() {
  success "Hostname configuration finished."
}

main() {
  SHORT_NAME="${1:-}"
  DOMAIN_NAME="${2:-}"

  run_action_workflow \
    "Set hostname" \
    "Proceed with hostname change to '$TARGET_FQDN'?" \
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
