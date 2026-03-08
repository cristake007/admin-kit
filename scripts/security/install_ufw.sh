#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and configure firewall tooling (UFW or firewalld backend).
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package install; firewall defaults/rules/service state may change

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
FIREWALL_SKIP_INSTALL=0

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

  ufw default "$expected_policy" "$direction" >/dev/null
}

configure_ufw_additively() {
  command -v ufw >/dev/null 2>&1 || { error "ufw command not found after install"; return 1; }
  ufw_set_default_if_needed incoming deny
  ufw_set_default_if_needed outgoing allow

  if ! ufw_rule_exists "OpenSSH"; then
    ufw allow OpenSSH >/dev/null
  fi

  if ! ufw status | grep -q "Status: active"; then
    ufw --force enable >/dev/null
  fi
}

show_message() {
  info "This action will install firewall tooling and apply additive baseline rules."
}

run_prereq_checks() {
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

check_already_installed() {
  if pkg_is_installed "$FIREWALL_PACKAGE"; then
    FIREWALL_SKIP_INSTALL=1
    info "Firewall package already installed: $FIREWALL_PACKAGE"
  fi
}

check_conflicts() { info "No explicit firewall package conflicts detected."; }

show_install_plan() {
  verify_item "package" "$FIREWALL_PACKAGE"
  if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
    verify_item "backend" "ufw (additive baseline rules)"
  else
    verify_item "backend" "$FIREWALL_BACKEND (service: $FIREWALL_SERVICE)"
  fi
}

run_install() {
  if [[ "$FIREWALL_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; package already present."
    return 0
  fi

  pkg_refresh_index --reason "firewall tooling installation"
  pkg_install "$FIREWALL_PACKAGE"
}

run_service_config() {
  if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
    configure_ufw_additively
  else
    service_enable_now "$FIREWALL_SERVICE"
  fi
}

post_install_verify() {
  verify_section "Post-install verification"
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

final_summary() { success "Firewall workflow finished."; }

main() {
  run_install_workflow \
    "Firewall installation" \
    "Proceed with firewall installation and baseline rules?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
