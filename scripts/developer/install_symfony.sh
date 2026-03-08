#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install Symfony CLI.
# Supports: debian, rhel
# Requires: root privileges, internet access
# Safe to rerun: yes
# Side effects: package installation, repository configuration

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib ui
require_lib os
require_lib pkg

install_cloudsmith_repo() {
  local setup_variant="${1:?setup variant required}"
  local setup_url="https://dl.cloudsmith.io/public/symfony/stable/setup.${setup_variant}.sh"
  local setup_script
  setup_script="$(mktemp)"

  info "Configuring Symfony repository (${setup_variant})."
  curl -fsSL "$setup_url" -o "$setup_script"
  bash "$setup_script"
  rm -f "$setup_script"
}

print_summary() {
  local install_method="$1"
  local version_output="$2"

  info "Verification summary:"
  info "- Install method: $install_method"
  if [[ -n "$version_output" ]]; then
    success "- Symfony CLI version: $version_output"
  else
    warn "- Symfony CLI is not installed. Next action: install manually from https://symfony.com/download"
  fi
}

main() {
  local install_method="not started"
  local version_output=""

  need_root
  os_detect

  if [[ "$OS_FAMILY" == "unsupported" ]]; then
    error "Unsupported Linux distribution: ID=${OS_ID:-unknown} ID_LIKE=${OS_ID_LIKE:-none}."
    return 1
  fi

  if command -v symfony >/dev/null 2>&1; then
    install_method="already installed"
    version_output="$(symfony version)"
    print_summary "$install_method" "$version_output"
    return 0
  fi

  info "This action can add a Symfony package repository and install Symfony CLI system-wide."
  info "Prerequisites: root privileges, network access, and supported distro family."
  info "Key side effects: repository configuration and package installation."
  info "Supported in this toolkit: Debian/Ubuntu and RHEL-family distributions."
  if ! confirm_proceed "Proceed with Symfony CLI installation?"; then
    operator_aborted
    print_summary "cancelled" ""
    return 0
  fi

  case "$OS_FAMILY" in
    debian)
      install_method="Cloudsmith APT repo + symfony-cli package"
      pkg_refresh_index --reason "symfony prerequisites installation"
      pkg_install ca-certificates curl gnupg
      install_cloudsmith_repo "deb"
      pkg_refresh_index --mode always --reason "symfony repository metadata"
      pkg_install symfony-cli
      ;;
    rhel)
      install_method="Cloudsmith RPM repo + symfony-cli package"
      pkg_refresh_index --reason "symfony prerequisites installation"
      pkg_install ca-certificates curl
      install_cloudsmith_repo "rpm"
      pkg_refresh_index --mode always --reason "symfony repository metadata"
      pkg_install symfony-cli
      ;;
    suse|arch)
      error "Symfony CLI installation is not supported by this toolkit on OS family '$OS_FAMILY'."
      print_summary "unsupported on $OS_FAMILY" ""
      return 1
      ;;
    *)
      error "Symfony CLI installation is unsupported for OS family '$OS_FAMILY'."
      return 1
      ;;
  esac

  if ! command -v symfony >/dev/null 2>&1; then
    error "Symfony CLI installation finished without creating the 'symfony' command."
    print_summary "$install_method" ""
    return 1
  fi

  version_output="$(symfony version)"
  print_summary "$install_method" "$version_output"
}

main "$@"
