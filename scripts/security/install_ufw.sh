#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and configure host firewall tool with additive reconciliation.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package install, firewall defaults/rules updates, service enablement

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib service
require_lib core

ufw_rule_exists() {
  local rule_label="${1:?rule label required}"
  ufw status | grep -Eq "(^|[[:space:]])${rule_label}([[:space:]]|$)"
}

ufw_set_default_if_needed() {
  local direction="${1:?direction required}"
  local expected_policy="${2:?policy required}"

  local current_policy
  current_policy="$(ufw status verbose 2>/dev/null | sed -n "s/.*Default:.*${direction}: \([^,)]*\).*/\1/p" | head -n1 | xargs || true)"

  if [[ "$current_policy" == "$expected_policy" ]]; then
    info "UFW default ${direction} already '${expected_policy}'"
    return 0
  fi

  info "Setting UFW default ${direction} to '${expected_policy}'"
  ufw default "$expected_policy" "$direction" >/dev/null
  success "Updated UFW default ${direction} policy"
}

configure_ufw_additively() {
  if ! command -v ufw >/dev/null 2>&1; then
    error "ufw command not found after install"
    return 1
  fi

  ufw_set_default_if_needed incoming deny
  ufw_set_default_if_needed outgoing allow

  if ufw_rule_exists "OpenSSH"; then
    info "UFW rule already present: allow OpenSSH"
  else
    info "Adding missing UFW rule: allow OpenSSH"
    ufw allow OpenSSH >/dev/null
    success "Added UFW rule: allow OpenSSH"
  fi

  if ufw status | grep -q "Status: active"; then
    success "UFW is already active"
  else
    info "Enabling UFW"
    ufw --force enable >/dev/null
    success "UFW enabled"
  fi
}

main() {
  need_root
  os_detect
  os_require_supported

  local firewall_pkg
  firewall_pkg="$(os_resolve_pkg firewall_tool)" || {
    error "No supported firewall package for distro family: $OS_FAMILY"
    return 1
  }

  pkg_update_index
  pkg_install "$firewall_pkg"

  if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
    configure_ufw_additively
  else
    service_enable_now "$(os_resolve_service firewall)"
  fi

  success "Firewall installation and reconciliation completed using $FIREWALL_BACKEND."
}

main "$@"
