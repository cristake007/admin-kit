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
require_lib ui

show_preinstall_message() {
  info "This action will install fail2ban and enable its service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: fail2ban packages and service state will be changed."
}

main() {
  need_root
  os_detect
  os_require_supported

  show_preinstall_message
  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_update_index
  pkg_install fail2ban
  service_enable_now fail2ban
  success "Fail2ban installation completed."
}

main "$@"
