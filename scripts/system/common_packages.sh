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
require_lib verify
require_lib install

COMMON_PROFILE="baseline"
declare -a COMMON_PACKAGES=()
COMMON_SKIP_INSTALL=0

bundle_to_array() {
  local capability="${1:?capability required}"
  local raw
  raw="$(os_resolve_pkg "$capability")" || return 1

  local -n out_ref="${2:?output array name required}"
  read -r -a out_ref <<<"$raw"
}

show_message() {
  info "This action will install the package profile: $COMMON_PROFILE."
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported

  local -a baseline_packages=()
  local -a ilias_packages=()
  bundle_to_array common_baseline_bundle baseline_packages

  case "$COMMON_PROFILE" in
    baseline) COMMON_PACKAGES=("${baseline_packages[@]}") ;;
    ilias)
      bundle_to_array ilias_required_bundle ilias_packages || {
        error "ILIAS package profile is unsupported on distro family: $OS_FAMILY"
        return 1
      }
      COMMON_PACKAGES=("${baseline_packages[@]}" "${ilias_packages[@]}")
      ;;
    *)
      error "Unknown package profile: $COMMON_PROFILE"
      return 1
      ;;
  esac
}

check_already_installed() {
  local missing=0
  local pkg
  for pkg in "${COMMON_PACKAGES[@]}"; do
    if ! pkg_is_installed "$pkg"; then
      missing=1
      break
    fi
  done

  if [[ "$missing" -eq 0 ]]; then
    COMMON_SKIP_INSTALL=1
    info "All packages for profile '$COMMON_PROFILE' are already installed."
  fi
}

check_conflicts() { info "No explicit conflicts for profile '$COMMON_PROFILE'."; }

show_install_plan() {
  verify_item "profile" "$COMMON_PROFILE"
  verify_item "packages" "${COMMON_PACKAGES[*]}"
}

run_install() {
  if [[ "$COMMON_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping package installation; profile already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "common package installation ($COMMON_PROFILE profile)"
  pkg_install "${COMMON_PACKAGES[@]}"
}

run_service_config() { info "No additional service configuration required for this profile."; }

post_install_verify() {
  verify_section "Post-install verification"
  local pkg
  for pkg in "${COMMON_PACKAGES[@]}"; do
    if pkg_is_installed "$pkg"; then
      verify_item "package $pkg" "installed"
    else
      verify_warning "package $pkg" "missing"
    fi
  done
}

final_summary() { success "Installed package profile: $COMMON_PROFILE"; }

main() {
  COMMON_PROFILE="${1:-baseline}"

  run_install_workflow \
    "Common packages installation" \
    "Proceed with common package profile '$COMMON_PROFILE'?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
