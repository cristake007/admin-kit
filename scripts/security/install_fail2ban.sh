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
require_lib verify
require_lib install

FAIL2BAN_PACKAGE="fail2ban"
FAIL2BAN_SERVICE="fail2ban"

show_preinstall_message() {
  info "This action will install fail2ban and enable its service."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: fail2ban packages and service state will be changed."
}

run_checks() {
  need_root
  os_detect
  os_require_supported
}

run_install() {
  pkg_refresh_index --reason "fail2ban installation"
  pkg_install "$FAIL2BAN_PACKAGE"
  service_enable_now "$FAIL2BAN_SERVICE"
}

post_install() {
  verify_section "Service status"
  verify_systemd_service "$FAIL2BAN_SERVICE" || true
}

main() {
  run_install_workflow \
    "Fail2ban installation" \
    "Proceed with fail2ban installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
