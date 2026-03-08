#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install Composer using distro packages or the official installer.
# Supports: debian, rhel, suse, arch (method availability varies)
# Requires: root privileges, network access for installation
# Safe to rerun: yes
# Side effects: package installation and/or /usr/local/bin/composer changes

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib os
require_lib pkg
require_lib ui
require_lib verify
require_lib install

COMPOSER_METHOD_DISTRO="distro"
COMPOSER_METHOD_OFFICIAL="official"
COMPOSER_SELECTED_METHOD="$COMPOSER_METHOD_DISTRO"
COMPOSER_SKIP_INSTALL=0

show_message() {
  info "This action will install Composer using distro packages or the official installer."
}

choose_method() {
  printf '\nChoose Composer install method:\n'
  printf '  1) Distro package manager\n'
  printf '  2) Official Composer installer\n'

  local choice
  read -r -p "Selection [1-2, default 1]: " choice

  case "${choice:-1}" in
    1) printf '%s\n' "$COMPOSER_METHOD_DISTRO" ;;
    2) printf '%s\n' "$COMPOSER_METHOD_OFFICIAL" ;;
    *) error "Invalid selection: ${choice}."; return 1 ;;
  esac
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported

  COMPOSER_SELECTED_METHOD="$(choose_method)"

  if [[ "$COMPOSER_SELECTED_METHOD" == "$COMPOSER_METHOD_OFFICIAL" ]]; then
    command -v php >/dev/null 2>&1 || { error "Official installer requires PHP."; return 1; }
    command -v curl >/dev/null 2>&1 || { error "Official installer requires curl."; return 1; }
  fi
}

check_already_installed() {
  if ! command -v composer >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$COMPOSER_SELECTED_METHOD" == "$COMPOSER_METHOD_DISTRO" ]] && pkg_is_installed composer; then
    COMPOSER_SKIP_INSTALL=1
    info "Composer already installed from distro packages."
    return 0
  fi

  if [[ "$COMPOSER_SELECTED_METHOD" == "$COMPOSER_METHOD_OFFICIAL" ]] && [[ -x /usr/local/bin/composer ]]; then
    COMPOSER_SKIP_INSTALL=1
    info "Composer already installed at /usr/local/bin/composer."
  fi
}

check_conflicts() { info "No explicit Composer conflicts detected."; }

show_install_plan() { verify_item "method" "$COMPOSER_SELECTED_METHOD"; }

install_via_distro_package() {
  pkg_refresh_index --reason "composer distro installation"
  pkg_install composer
}

install_via_official_installer() {
  local installer='/tmp/composer-setup.php'
  curl -fsSL https://getcomposer.org/installer -o "$installer"
  php "$installer" --install-dir=/usr/local/bin --filename=composer --quiet
  rm -f "$installer"
}

run_install() {
  if [[ "$COMPOSER_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping installation; selected method already satisfied."
    return 0
  fi

  if [[ "$COMPOSER_SELECTED_METHOD" == "$COMPOSER_METHOD_DISTRO" ]]; then
    install_via_distro_package
  else
    install_via_official_installer
  fi
}

run_service_config() { info "No service configuration required for Composer."; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_item "composer path" "$(command -v composer 2>/dev/null || echo not-found)"
  verify_command "composer --version" composer --version || true
}

final_summary() { success "Composer installation workflow finished."; }

main() {
  run_install_workflow \
    "Composer installation" \
    "Proceed with Composer installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
