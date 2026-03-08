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

main() {
  need_root
  os_detect
  os_require_supported

  if service_exists nginx && service_is_active nginx; then
    error "Nginx is active. Stop nginx before installing Apache to avoid port conflicts."
    return 1
  fi

  local apache_pkg="apache2"
  local apache_service="apache2"
  case "$OS_FAMILY" in
    rhel|suse|arch) apache_pkg="httpd"; apache_service="httpd" ;;
  esac

  pkg_update_index
  pkg_install "$apache_pkg"
  service_enable_now "$apache_service"
  success "Apache installed and enabled ($apache_service)."
}

main "$@"
