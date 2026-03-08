#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install package bundles for baseline system or ILIAS workflow.
# Supports: debian, rhel, suse, arch (baseline); debian, rhel, suse (ilias profile)
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib core
require_lib ui
require_lib install

COMMON_PROFILE="baseline"
declare -a COMMON_PACKAGES=()

bundle_to_array() {
  local capability="${1:?capability required}"
  local raw
  raw="$(os_resolve_pkg "$capability")" || return 1

  local -n out_ref="${2:?output array name required}"
  read -r -a out_ref <<<"$raw"
}

show_preinstall_message() {
  info "This action will install the package profile: $COMMON_PROFILE."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: additional system packages will be installed."
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  local -a baseline_packages=()
  local -a ilias_packages=()

  bundle_to_array common_baseline_bundle baseline_packages

  case "$COMMON_PROFILE" in
    baseline)
      COMMON_PACKAGES=("${baseline_packages[@]}")
      ;;
    ilias)
      if ! bundle_to_array ilias_required_bundle ilias_packages; then
        error "ILIAS package profile is unsupported on distro family: $OS_FAMILY"
        return 1
      fi
      COMMON_PACKAGES=("${baseline_packages[@]}" "${ilias_packages[@]}")
      ;;
    *)
      error "Unknown package profile: $COMMON_PROFILE"
      error "Usage: $0 [baseline|ilias]"
      return 1
      ;;
  esac
}

run_install() {
  pkg_refresh_index --reason "common package installation ($COMMON_PROFILE profile)"
  pkg_install "${COMMON_PACKAGES[@]}"
}

post_install() {
  success "Installed package profile: $COMMON_PROFILE"
}

main() {
  COMMON_PROFILE="${1:-baseline}"

  run_install_workflow \
    "Common packages installation" \
    "Proceed with common package profile '$COMMON_PROFILE'?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
