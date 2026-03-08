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
FAIL2BAN_SKIP_INSTALL=0

show_message() { info "This action will install fail2ban and enable its service."; }

run_prereq_checks() { need_root; os_detect; os_require_supported; }

check_already_installed() {
  if pkg_is_installed "$FAIL2BAN_PACKAGE" && service_exists "$FAIL2BAN_SERVICE" && service_is_active "$FAIL2BAN_SERVICE"; then
    FAIL2BAN_SKIP_INSTALL=1
    info "Fail2ban package and active service already present."
  fi
}

check_conflicts() { :; }

show_install_plan() { verify_item "package" "$FAIL2BAN_PACKAGE"; verify_item "service" "$FAIL2BAN_SERVICE"; }

run_install() {
  if [[ "$FAIL2BAN_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; target already satisfied."
    return 0
  fi
  pkg_refresh_index --reason "fail2ban installation"
  pkg_install "$FAIL2BAN_PACKAGE"
}

run_service_config() { service_enable_now "$FAIL2BAN_SERVICE"; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_systemd_service "$FAIL2BAN_SERVICE" || true
}

final_summary() { success "Fail2ban installation workflow finished."; }

main() {
  run_install_workflow \
    "Fail2ban installation" \
    "Proceed with fail2ban installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
