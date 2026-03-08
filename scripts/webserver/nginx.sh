#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and enable Nginx.
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

NGINX_PACKAGE="nginx"
NGINX_SERVICE="nginx"

show_preinstall_message() {
  info "This action will install Nginx and enable its service at boot."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: nginx package installation and service activation."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  local apache_service
  apache_service="$(os_resolve_service apache)"

  if service_exists "$apache_service" && service_is_active "$apache_service"; then
    error "Apache is active. Stop $apache_service before installing Nginx to avoid port conflicts."
    return 1
  fi
}

run_install() {
  pkg_refresh_index --reason "nginx installation"
  pkg_install "$NGINX_PACKAGE"
  service_enable_now "$NGINX_SERVICE"
}

post_install() {
  verify_section "Service status"
  verify_systemd_service "$NGINX_SERVICE" || true
}

main() {
  run_install_workflow \
    "Nginx installation" \
    "Proceed with Nginx installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
