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
require_lib install

SYMFONY_INSTALL_METHOD="not started"
SYMFONY_SKIP_INSTALL=0

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

show_preinstall_message() {
  info "This action can add a Symfony package repository and install Symfony CLI system-wide."
  info "Prerequisites: root privileges, network access, and supported distro family."
  info "Key side effects: repository configuration and package installation."
  info "Supported in this toolkit: Debian/Ubuntu and RHEL-family distributions."
}

run_checks() {
  need_root
  os_detect

  if [[ "$OS_FAMILY" == "unsupported" ]]; then
    error "Unsupported Linux distribution: ID=${OS_ID:-unknown} ID_LIKE=${OS_ID_LIKE:-none}."
    return 1
  fi

  if command -v symfony >/dev/null 2>&1; then
    SYMFONY_INSTALL_METHOD="already installed"
    SYMFONY_SKIP_INSTALL=1
    success "Symfony CLI already installed: $(symfony version)"
    return 0
  fi

  case "$OS_FAMILY" in
    debian) SYMFONY_INSTALL_METHOD="Cloudsmith APT repo + symfony-cli package" ;;
    rhel) SYMFONY_INSTALL_METHOD="Cloudsmith RPM repo + symfony-cli package" ;;
    suse|arch)
      error "Symfony CLI installation is not supported by this toolkit on OS family '$OS_FAMILY'."
      return 1
      ;;
    *)
      error "Symfony CLI installation is unsupported for OS family '$OS_FAMILY'."
      return 1
      ;;
  esac
}

run_install() {
  if [[ "$SYMFONY_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping Symfony install stage; command already available."
    return 0
  fi

  case "$OS_FAMILY" in
    debian)
      pkg_refresh_index --reason "symfony prerequisites installation"
      pkg_install ca-certificates curl gnupg
      install_cloudsmith_repo "deb"
      pkg_refresh_index --mode always --reason "symfony repository metadata"
      pkg_install symfony-cli
      ;;
    rhel)
      pkg_refresh_index --reason "symfony prerequisites installation"
      pkg_install ca-certificates curl
      install_cloudsmith_repo "rpm"
      pkg_refresh_index --mode always --reason "symfony repository metadata"
      pkg_install symfony-cli
      ;;
  esac
}

post_install() {
  info "Verification summary:"
  info "- Install method: $SYMFONY_INSTALL_METHOD"
  if command -v symfony >/dev/null 2>&1; then
    success "- Symfony CLI version: $(symfony version)"
  else
    warn "- Symfony CLI is not installed. Next action: install manually from https://symfony.com/download"
  fi
}

main() {
  run_install_workflow \
    "Symfony CLI installation" \
    "Proceed with Symfony CLI installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
