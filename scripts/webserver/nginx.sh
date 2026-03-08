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

show_preinstall_message() {
  info "This action will install Nginx and enable its service at boot."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: nginx package installation and service activation."
}

main() {
  need_root
  os_detect
  os_require_supported

  local apache_service
  apache_service="$(os_resolve_service apache)"

  if service_exists "$apache_service" && service_is_active "$apache_service"; then
    error "Apache is active. Stop $apache_service before installing Nginx to avoid port conflicts."
    return 1
  fi

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_update_index
  pkg_install nginx
  service_enable_now nginx
  success "Nginx installed and enabled."
}

main "$@"
