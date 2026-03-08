#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install certbot and common webserver plugin package.
# Supports: debian, rhel, suse
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib core
require_lib ui
require_lib verify
require_lib install

CERTBOT_PACKAGE="certbot"
CERTBOT_PLUGIN_PACKAGE=""
CERTBOT_SKIP_INSTALL=0

show_message() {
  info "This action will install certbot and, when detected, the Apache or Nginx plugin package."
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "Certbot helper script is not supported on arch in this toolkit."
    return 1
  fi
}

check_already_installed() {
  local apache_pkg
  apache_pkg="$(os_resolve_pkg apache_server)"

  CERTBOT_PLUGIN_PACKAGE=""
  if pkg_is_installed "$apache_pkg"; then
    CERTBOT_PLUGIN_PACKAGE="python3-certbot-apache"
  elif pkg_is_installed nginx; then
    CERTBOT_PLUGIN_PACKAGE="python3-certbot-nginx"
  fi

  if pkg_is_installed "$CERTBOT_PACKAGE"; then
    if [[ -z "$CERTBOT_PLUGIN_PACKAGE" ]] || pkg_is_installed "$CERTBOT_PLUGIN_PACKAGE"; then
      CERTBOT_SKIP_INSTALL=1
      info "Certbot target state already satisfied."
    fi
  fi
}

check_conflicts() { info "No explicit certbot conflicts detected."; }

show_install_plan() {
  verify_item "package" "$CERTBOT_PACKAGE"
  if [[ -n "$CERTBOT_PLUGIN_PACKAGE" ]]; then
    verify_item "plugin package" "$CERTBOT_PLUGIN_PACKAGE"
  else
    verify_item "plugin package" "none auto-detected"
  fi
}

run_install() {
  if [[ "$CERTBOT_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "certbot installation"
  pkg_install "$CERTBOT_PACKAGE"
  if [[ -n "$CERTBOT_PLUGIN_PACKAGE" ]]; then
    pkg_install "$CERTBOT_PLUGIN_PACKAGE"
  else
    warn "No Apache/Nginx package detected; installed certbot only."
  fi
}

run_service_config() { info "No service configuration required for certbot package installation."; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "certbot --version" certbot --version || true
}

final_summary() {
  success "Certbot installation workflow finished."
}

main() {
  run_install_workflow \
    "Certbot installation" \
    "Proceed with certbot installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
