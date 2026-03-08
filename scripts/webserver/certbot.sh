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
require_lib install

CERTBOT_PACKAGE="certbot"
CERTBOT_PLUGIN_PACKAGE=""

show_preinstall_message() {
  info "This action will install certbot and, when detected, the Apache or Nginx plugin package."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: certbot packages will be installed."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "Certbot helper script is not supported on arch in this toolkit."
    return 1
  fi

  local apache_pkg
  apache_pkg="$(os_resolve_pkg apache_server)"

  CERTBOT_PLUGIN_PACKAGE=""
  if pkg_is_installed "$apache_pkg"; then
    CERTBOT_PLUGIN_PACKAGE="python3-certbot-apache"
  elif pkg_is_installed nginx; then
    CERTBOT_PLUGIN_PACKAGE="python3-certbot-nginx"
  fi
}

run_install() {
  pkg_refresh_index --reason "certbot installation"
  pkg_install "$CERTBOT_PACKAGE"
  if [[ -n "$CERTBOT_PLUGIN_PACKAGE" ]]; then
    pkg_install "$CERTBOT_PLUGIN_PACKAGE"
  else
    warn "No Apache/Nginx package detected; installed certbot only."
  fi
}

post_install() {
  if [[ -n "$CERTBOT_PLUGIN_PACKAGE" ]]; then
    success "Certbot plugin installed: $CERTBOT_PLUGIN_PACKAGE"
  fi
}

main() {
  run_install_workflow \
    "Certbot installation" \
    "Proceed with certbot installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
