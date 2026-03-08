#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install MySQL-compatible server package.
# Supports: debian, rhel, suse
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

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "MySQL installer is unsupported on arch in this toolkit. Use MariaDB instead."
    return 1
  fi

  local pkg_name
  local svc_name
  pkg_name="$(os_resolve_pkg mysql_server)" || {
    error "MySQL package is unsupported on distro family: $OS_FAMILY"
    return 1
  }
  svc_name="$(os_resolve_service mysql)"

  pkg_update_index
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  success "MySQL installation completed."
}

main "$@"
