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

COMPOSER_METHOD_DISTRO="distro"
COMPOSER_METHOD_OFFICIAL="official"


show_preinstall_message() {
  info "This action will install Composer using the selected method."
  info "Prerequisites: root privileges, network access, and method-specific dependencies (php/curl for official installer)."
  info "- Method 1: distro package manager install (recommended for distro-managed updates)."
  info "- Method 2: official Composer installer (installs /usr/local/bin/composer)."
  info "Key side effects: package installation and/or /usr/local/bin/composer changes."
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
    *)
      error "Invalid selection: ${choice}."
      return 1
      ;;
  esac
}

method_is_supported() {
  local method="${1:?method required}"

  case "$method" in
    "$COMPOSER_METHOD_DISTRO")
      if [[ "$OS_FAMILY" == "unsupported" || -z "$PKG_BACKEND" ]]; then
        error "Distro package install is unsupported on this system."
        return 1
      fi
      return 0
      ;;
    "$COMPOSER_METHOD_OFFICIAL")
      if ! command -v php >/dev/null 2>&1; then
        error "Official installer requires PHP, but 'php' is not installed."
        return 1
      fi
      if ! command -v curl >/dev/null 2>&1; then
        error "Official installer requires curl, but 'curl' is not installed."
        return 1
      fi
      return 0
      ;;
    *)
      error "Unsupported Composer installation method: $method"
      return 1
      ;;
  esac
}

selected_method_satisfied() {
  local method="${1:?method required}"

  if ! command -v composer >/dev/null 2>&1; then
    return 1
  fi

  if [[ "$method" == "$COMPOSER_METHOD_DISTRO" ]]; then
    if pkg_is_installed composer; then
      info "Composer is already installed from distro packages."
      return 0
    fi
    return 1
  fi

  if [[ -x /usr/local/bin/composer ]]; then
    info "Composer is already installed at /usr/local/bin/composer."
    return 0
  fi

  return 1
}

install_via_distro_package() {
  pkg_refresh_index --reason "composer distro installation"
  pkg_install composer
}

install_via_official_installer() {
  local installer='/tmp/composer-setup.php'

  info "Downloading Composer installer"
  curl -fsSL https://getcomposer.org/installer -o "$installer"

  info "Installing Composer to /usr/local/bin/composer"
  php "$installer" --install-dir=/usr/local/bin --filename=composer --quiet
  rm -f "$installer"
}

print_verification_summary() {
  verify_section "Composer"

  if command -v composer >/dev/null 2>&1; then
    verify_item "composer path" "$(command -v composer)"
  else
    verify_warning "composer path" "not found"
  fi

  verify_command "composer --version" composer --version || true
}

main() {
  need_root
  os_detect
  os_require_supported

  show_preinstall_message

  local selected_method
  selected_method="$(choose_method)"

  if ! method_is_supported "$selected_method"; then
    warn "No changes were made."
    return 1
  fi

  if selected_method_satisfied "$selected_method"; then
    success "No installation changes required."
    print_verification_summary
    return 0
  fi

  local action_desc="Install Composer using distro package manager"
  if [[ "$selected_method" == "$COMPOSER_METHOD_OFFICIAL" ]]; then
    action_desc="Install Composer using the official installer"
  fi

  if ! confirm_proceed "${action_desc}. Proceed?"; then
    operator_aborted
    print_verification_summary
    return 0
  fi

  if [[ "$selected_method" == "$COMPOSER_METHOD_DISTRO" ]]; then
    install_via_distro_package
  else
    install_via_official_installer
  fi

  success "Composer installation workflow completed."
  print_verification_summary
}

main "$@"
