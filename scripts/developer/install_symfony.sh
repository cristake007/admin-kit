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
require_lib verify
require_lib install

SYMFONY_INSTALL_METHOD="not started"
SYMFONY_SKIP_INSTALL=0

install_cloudsmith_repo() {
  local setup_variant="${1:?setup variant required}"
  local setup_url="https://dl.cloudsmith.io/public/symfony/stable/setup.${setup_variant}.sh"
  local setup_script
  setup_script="$(mktemp)"

  curl -fsSL "$setup_url" -o "$setup_script"
  bash "$setup_script"
  rm -f "$setup_script"
}

show_message() {
  info "This action can add a Symfony package repository and install Symfony CLI system-wide."
}

run_prereq_checks() {
  need_root
  os_detect

  if [[ "$OS_FAMILY" == "unsupported" ]]; then
    error "Unsupported Linux distribution: ID=${OS_ID:-unknown} ID_LIKE=${OS_ID_LIKE:-none}."
    return 1
  fi

  case "$OS_FAMILY" in
    debian) SYMFONY_INSTALL_METHOD="Cloudsmith APT repo + symfony-cli package" ;;
    rhel) SYMFONY_INSTALL_METHOD="Cloudsmith RPM repo + symfony-cli package" ;;
    *)
      error "Symfony CLI installation is unsupported on OS family '$OS_FAMILY'."
      return 1
      ;;
  esac
}

check_already_installed() {
  if command -v symfony >/dev/null 2>&1; then
    SYMFONY_INSTALL_METHOD="already installed"
    SYMFONY_SKIP_INSTALL=1
    info "Symfony CLI already installed."
  fi
}

check_conflicts() { info "No explicit Symfony package conflicts detected."; }

show_install_plan() { verify_item "install method" "$SYMFONY_INSTALL_METHOD"; }

run_install() {
  if [[ "$SYMFONY_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping installation; target already satisfied."
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

run_service_config() { info "No service configuration required for Symfony CLI."; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "symfony version" symfony version || true
}

final_summary() { success "Symfony installation workflow finished."; }

main() {
  run_install_workflow \
    "Symfony CLI installation" \
    "Proceed with Symfony CLI installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
