#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and enable a host firewall tool.
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

  case "$OS_FAMILY" in
    debian)
      pkg_update_index
      pkg_install ufw
      if command -v ufw >/dev/null 2>&1; then
        ufw status >/dev/null 2>&1 || true
      fi
      success "UFW installed. Configure rules before enabling deny policies."
      ;;
    rhel|suse|arch)
      pkg_update_index
      pkg_install firewalld
      service_enable_now firewalld
      success "firewalld installed and enabled."
      ;;
    *)
      error "No supported firewall workflow for family: $OS_FAMILY"
      return 1
      ;;
  esac
}

main "$@"
