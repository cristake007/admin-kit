#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install extrepo on Debian-family systems.
# Supports: debian
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib os
require_lib pkg
require_lib ui
require_lib verify
require_lib install

EXTREPO_PACKAGE="extrepo"
EXTREPO_SKIP_INSTALL=0

show_message() { info "This action will install the extrepo package."; }

run_prereq_checks() {
  need_root
  os_detect
  if [[ "$OS_FAMILY" != "debian" ]]; then
    error "Extrepo is supported only on Debian/Ubuntu systems."
    return 1
  fi
}

check_already_installed() {
  if pkg_is_installed "$EXTREPO_PACKAGE"; then
    EXTREPO_SKIP_INSTALL=1
    info "extrepo package already installed."
  fi
}

check_conflicts() { info "No explicit extrepo conflicts detected."; }

show_install_plan() { verify_item "package" "$EXTREPO_PACKAGE"; }

run_install() {
  if [[ "$EXTREPO_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "extrepo installation"
  pkg_install "$EXTREPO_PACKAGE"
}

run_service_config() { info "No service configuration required for extrepo."; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "extrepo --version" extrepo --version || true
}

final_summary() { success "Extrepo installation workflow finished."; }

main() {
  run_install_workflow \
    "Extrepo installation" \
    "Proceed with extrepo installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
