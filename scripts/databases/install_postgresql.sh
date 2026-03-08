#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install PostgreSQL server.
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

  local pkg_name
  local svc_name
  pkg_name="$(os_resolve_pkg postgresql_server)"
  svc_name="$(os_resolve_service postgresql)"

  pkg_update_index
  pkg_install "$pkg_name"
  service_enable_now "$svc_name"
  success "PostgreSQL installation completed."
}

main "$@"
