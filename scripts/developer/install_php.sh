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

PHP_PACKAGES_RAW=""

declare -a PHP_PACKAGES=()

show_preinstall_message() {
  info "This action will install PHP runtime packages and common extensions."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: PHP packages will be installed."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  PHP_PACKAGES_RAW="$(os_resolve_pkg php_runtime_bundle)"
  read -r -a PHP_PACKAGES <<<"$PHP_PACKAGES_RAW"
}

run_install() {
  pkg_refresh_index --reason "php installation"
  pkg_install "${PHP_PACKAGES[@]}"
}

post_install() {
  verify_section "PHP runtime"
  verify_command "php --version" php --version || true
}

main() {
  run_install_workflow \
    "PHP installation" \
    "Proceed with PHP installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
