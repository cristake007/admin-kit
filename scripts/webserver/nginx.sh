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
NGINX_SKIP_INSTALL=0

show_message() { info "This action will install Nginx and enable its service at boot."; }

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported
}

check_already_installed() {
  if pkg_is_installed "$NGINX_PACKAGE" && service_exists "$NGINX_SERVICE" && service_is_active "$NGINX_SERVICE"; then
    NGINX_SKIP_INSTALL=1
    info "Nginx package and active service already present."
  fi
}

check_conflicts() {
  local apache_service
  apache_service="$(os_resolve_service apache)"
  if service_exists "$apache_service" && service_is_active "$apache_service"; then
    error "Apache is active. Stop $apache_service before installing Nginx to avoid port conflicts."
    return 1
  fi
}

show_install_plan() {
  verify_item "package" "$NGINX_PACKAGE"
  verify_item "service" "$NGINX_SERVICE"
}

run_install() {
  if [[ "$NGINX_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi
  pkg_refresh_index --reason "nginx installation"
  pkg_install "$NGINX_PACKAGE"
}

run_service_config() { service_enable_now "$NGINX_SERVICE"; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_systemd_service "$NGINX_SERVICE" || true
}

final_summary() { success "Nginx installation workflow finished."; }

main() {
  run_install_workflow \
    "Nginx installation" \
    "Proceed with Nginx installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
