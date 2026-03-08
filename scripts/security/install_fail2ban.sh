#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install and enable fail2ban.
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

  pkg_update_index
  pkg_install fail2ban
  service_enable_now fail2ban
  success "Fail2ban installation completed."
}

main "$@"
