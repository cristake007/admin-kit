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

show_preinstall_message() {
  local target_fqdn="${1:?fqdn required}"
  info "This action will set the static hostname to '$target_fqdn' and update /etc/hosts entry 127.0.1.1."
  info "Prerequisites: root privileges and a valid hostname/domain format."
  info "Key side effects: hostnamectl state and /etc/hosts will be modified (with backup)."
}

main() {
  need_root

  local short_name="${1:-}"
  local domain_name=""
  local domain_was_provided="false"

  if [[ "$#" -ge 2 ]]; then
    domain_name="$2"
    domain_was_provided="true"
  fi

  if [[ -z "$short_name" ]]; then
    read -r -p "Enter short hostname: " short_name
  fi

  if [[ "$domain_was_provided" == "false" ]]; then
    info "Domain input is optional. Leave blank (\"\") to configure only the short hostname."
    read -r -p "Enter domain (optional): " domain_name
  fi

  if ! validate_hostname "$short_name"; then
    error "Invalid hostname '$short_name': use only lowercase letters, digits, and hyphens; must start/end with letter or digit; max 63 chars."
    info "Valid short hostname examples: app01, web-server, db2"
    return 1
  fi
  if ! validate_domain "$domain_name"; then
    error "Invalid domain '$domain_name': use dot-separated labels with lowercase letters, digits, and hyphens; each label must start/end with letter or digit."
    info "Valid FQDN examples: app01.example.com, web-server.prod.local, db2.internal.example"
    return 1
  fi

  local fqdn="$short_name"
  if [[ -n "$domain_name" ]]; then
    fqdn="$short_name.$domain_name"
  fi

  show_preinstall_message "$fqdn"

  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  local current_static
  current_static="$(hostnamectl --static 2>/dev/null || true)"

  local step_name=""
  local command_context=""

  step_name="apply hostname via hostnamectl"
  command_context="hostnamectl set-hostname '$fqdn'"
  if [[ "$current_static" == "$fqdn" ]]; then
    info "Step skipped ($step_name): hostname already set to '$fqdn'."
  elif ! hostnamectl set-hostname "$fqdn"; then
    error "Failed step: $step_name"
    error "Command: $command_context"
    return 1
  else
    success "Step completed: $step_name"
  fi

  step_name="backup /etc/hosts"
  command_context="backup_file /etc/hosts"
  if ! backup_file /etc/hosts; then
    error "Failed step: $step_name"
    error "Command: $command_context"
    return 1
  fi
  success "Step completed: $step_name"

  step_name="update hosts mapping"
  command_context="replace_or_add_key_value /etc/hosts '127.0.1.1' '$fqdn $short_name'"
  local desired_hosts_value="$fqdn $short_name"
  local current_hosts_value
  current_hosts_value="$(awk '$1 == "127.0.1.1" { $1=""; sub(/^[[:space:]]+/, ""); print; exit }' /etc/hosts || true)"
  if [[ "$current_hosts_value" == "$desired_hosts_value" ]]; then
    info "Step skipped ($step_name): /etc/hosts already maps 127.0.1.1 to '$desired_hosts_value'."
  elif ! replace_or_add_key_value /etc/hosts "127.0.1.1" "$desired_hosts_value"; then
    error "Failed step: $step_name"
    error "Command: $command_context"
    return 1
  else
    success "Step completed: $step_name"
  fi

  local effective_static
  local effective_fqdn
  effective_static="$(hostnamectl --static 2>/dev/null || true)"
  effective_fqdn="$(hostnamectl --fqdn 2>/dev/null || true)"

  success "Hostname configuration finished."
  info "Verification: hostnamectl --static => ${effective_static:-<empty>}"
  info "Verification: hostnamectl --fqdn   => ${effective_fqdn:-<empty>}"
}

main "$@"
