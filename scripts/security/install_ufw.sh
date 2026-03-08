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
require_lib ui
require_lib verify
require_lib install

FIREWALL_PACKAGE=""
FIREWALL_SERVICE=""

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

show_preinstall_message() {
  info "This action will install the distro firewall tool and apply additive baseline rules."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: firewall defaults/rules may change and firewall service may be enabled."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  FIREWALL_PACKAGE="$(os_resolve_pkg firewall_tool)" || {
    error "No supported firewall package for distro family: $OS_FAMILY"
    return 1
  }

  if [[ "$FIREWALL_BACKEND" != "ufw" ]]; then
    FIREWALL_SERVICE="$(os_resolve_service firewall)"
  fi
}

run_install() {
  pkg_refresh_index --reason "firewall tooling installation"
  pkg_install "$FIREWALL_PACKAGE"

  if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
    configure_ufw_additively
  else
    service_enable_now "$FIREWALL_SERVICE"
  fi
}

post_install() {
  verify_section "Firewall status"
  if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
    if command -v ufw >/dev/null 2>&1; then
      verify_item "ufw status" "$(ufw status | head -n1)"
    else
      verify_warning "ufw status" "command not found"
    fi
  else
    verify_systemd_service "$FIREWALL_SERVICE" || true
  fi
}

main() {
  run_install_workflow \
    "Firewall installation" \
    "Proceed with firewall installation and additive baseline rules?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
