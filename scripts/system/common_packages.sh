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

bundle_to_array() {
  local capability="${1:?capability required}"
  local raw
  raw="$(os_resolve_pkg "$capability")" || return 1

  local -n out_ref="${2:?output array name required}"
  read -r -a out_ref <<<"$raw"
}

show_preinstall_message() {
  local profile="${1:-baseline}"
  info "This action will install the package profile: $profile."
  info "Prerequisites: root privileges and package repository access."
  info "Key side effects: additional system packages will be installed."
}

main() {
  need_root
  os_detect
  os_require_supported

  local profile="${1:-baseline}"
  local -a packages=()
  local -a baseline_packages=()
  local -a ilias_packages=()

  bundle_to_array common_baseline_bundle baseline_packages

  show_preinstall_message "$profile"

  case "$profile" in
    baseline)
      packages=("${baseline_packages[@]}")
      ;;
    ilias)
      if ! bundle_to_array ilias_required_bundle ilias_packages; then
        error "ILIAS package profile is unsupported on distro family: $OS_FAMILY"
        return 1
      fi
      packages=("${baseline_packages[@]}" "${ilias_packages[@]}")
      ;;
    *)
      error "Unknown package profile: $profile"
      error "Usage: $0 [baseline|ilias]"
      return 1
      ;;
  esac

  if ! confirm_proceed; then
    operator_aborted
    return 0
  fi

  pkg_refresh_index --reason "common package installation ($profile profile)"
  pkg_install "${packages[@]}"
  success "Installed package profile: $profile"
}

main "$@"
