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

  local pkg_name="mysql-server"
  local svc_name="mysql"

  case "$OS_FAMILY" in
    debian) pkg_name="default-mysql-server"; svc_name="mysql" ;;
    rhel|suse) pkg_name="mysql-server"; svc_name="mysqld" ;;
    arch)
      error "MySQL installer is unsupported on arch in this toolkit. Use MariaDB instead."
      return 1
      ;;
    *)
      error "Unsupported distro family for MySQL installer: $OS_FAMILY"
      return 1
      ;;
  esac

  pkg_update_index
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  success "MySQL installation completed."
}

main "$@"
