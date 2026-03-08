#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and enable Apache HTTP server.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package install and service enablement

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

show_preinstall_message() {
  info "This action will install Apache HTTP server and enable its service at boot."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: apache package installation and service activation."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  if service_exists nginx && service_is_active nginx; then
    error "Nginx is active. Stop nginx before installing Apache to avoid port conflicts."
    return 1
  fi

  local apache_pkg
  apache_pkg="$(os_resolve_pkg apache_server)"
  APACHE_PKG="$apache_pkg"
  APACHE_SERVICE="$(os_resolve_service apache)"
}

run_install() {
  pkg_refresh_index --reason "apache installation"
  pkg_install "$APACHE_PKG"
  service_enable_now "$APACHE_SERVICE"
}

post_install() {
  verify_section "Service status"
  verify_systemd_service "$APACHE_SERVICE" || true
}

main() {
  run_install_workflow \
    "Apache installation" \
    "Proceed with Apache installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
