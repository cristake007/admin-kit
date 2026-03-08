#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install PHP runtime and common extensions.
# Supports: debian, rhel, suse, arch
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

declare -a PHP_PACKAGES=()
PHP_SKIP_INSTALL=0

show_message() { info "This action will install PHP runtime packages and common extensions."; }

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported

  local raw
  raw="$(os_resolve_pkg php_runtime_bundle)"
  read -r -a PHP_PACKAGES <<<"$raw"
}

check_already_installed() {
  local missing=0
  local pkg
  for pkg in "${PHP_PACKAGES[@]}"; do
    if ! pkg_is_installed "$pkg"; then
      missing=1
      break
    fi
  done
  if [[ "$missing" -eq 0 ]]; then
    PHP_SKIP_INSTALL=1
    info "PHP package bundle already installed."
  fi
}

check_conflicts() { :; }

show_install_plan() { verify_item "packages" "${PHP_PACKAGES[*]}"; }

run_install() {
  if [[ "$PHP_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "php installation"
  pkg_install "${PHP_PACKAGES[@]}"
}

run_service_config() { :; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "php --version" php --version || true
}

final_summary() { success "PHP installation workflow finished."; }

main() {
  run_install_workflow \
    "PHP installation" \
    "Proceed with PHP installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
