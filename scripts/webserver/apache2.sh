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

APACHE_PKG=""
APACHE_SERVICE=""
APACHE_SKIP_INSTALL=0

show_message() {
  info "This action will install Apache HTTP server and enable its service at boot."
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported
  APACHE_PKG="$(os_resolve_pkg apache_server)"
  APACHE_SERVICE="$(os_resolve_service apache)"
}

check_already_installed() {
  if pkg_is_installed "$APACHE_PKG" && service_exists "$APACHE_SERVICE" && service_is_active "$APACHE_SERVICE"; then
    APACHE_SKIP_INSTALL=1
    info "Apache package and active service already present."
  fi
}

check_conflicts() {
  if service_exists nginx && service_is_active nginx; then
    error "Nginx is active. Stop nginx before installing Apache to avoid port conflicts."
    return 1
  fi
}

show_install_plan() {
  verify_item "package" "$APACHE_PKG"
  verify_item "service" "$APACHE_SERVICE"
}

run_install() {
  if [[ "$APACHE_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi
  pkg_refresh_index --reason "apache installation"
  pkg_install "$APACHE_PKG"
}

run_service_config() {
  service_enable_now "$APACHE_SERVICE"
}

post_install_verify() {
  verify_section "Post-install verification"
  verify_systemd_service "$APACHE_SERVICE" || true
}

final_summary() {
  success "Apache installation workflow finished."
}

main() {
  run_install_workflow \
    "Apache installation" \
    "Proceed with Apache installation?" \
    show_message \
    run_prereq_checks \
    check_already_installed \
    check_conflicts \
    show_install_plan \
    run_install \
    run_service_config \
    post_install_verify \
    final_summary
}

main "$@"
