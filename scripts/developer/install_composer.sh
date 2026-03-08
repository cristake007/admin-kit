#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

install_via_apt() {
  echo_note "Updating package lists..."
  apt_update

  # IMPORTANT: APT-only check (dpkg), to avoid misreporting a binary/snap install as APT
  if dpkg -s composer >/dev/null 2>&1; then
    echo_success "Composer is already installed via APT."
  else
    echo_note "Installing Composer (APT)..."
    apt_install composer
    echo_success "Composer installed (APT)."
  fi
}

install_via_binary() {
  # Ensure deps
  if ! command -v php >/dev/null 2>&1; then
    echo_info "php-cli not found; installing..."
    apt_update
    apt_install php-cli
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo_info "curl not found; installing..."
    apt_update
    apt_install curl
  fi

  # If present (any source: apt/snap/flatpak/binary), skip install
  if apt_is_installed composer; then
    echo_info "Composer is already present. Skipping binary install."
    return 0
  fi

  echo_info "Composer not found, proceeding with installation."
  echo_note "Installing Composer via official binary installer..."

  EXPECTED_SIGNATURE="$(curl -fsSL https://composer.github.io/installer.sig)" || {
    echo_error "Could not fetch installer signature."; return 1; }
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" || {
    echo_error "Could not download installer."; return 1; }
  ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [[ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]]; then
    echo_error "ERROR: Invalid installer signature."
    rm -f composer-setup.php
    return 1
  fi

  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rc=$?
  rm -f composer-setup.php
  if [ "$rc" -ne 0 ]; then
    echo_error "Composer installer failed (rc=$rc)."
    return "$rc"
  fi

  # Make sure it's executable and callable without 'php ...'
  chmod +x /usr/local/bin/composer || true
  echo_success "Composer installed (binary)."

  return 0
}

print_composer_version_once() {
  echo_note "Composer version:"
  if id -u www-data >/dev/null 2>&1; then
    # Try as www-data first (useful for web projects)
    sudo -u www-data composer --version 2>/dev/null \
      || sudo -u www-data php /usr/local/bin/composer --version 2>/dev/null \
      || composer --version 2>/dev/null \
      || php /usr/local/bin/composer --version 2>/dev/null \
      || true
  else
    composer --version 2>/dev/null \
      || php /usr/local/bin/composer --version 2>/dev/null \
      || true
  fi
}

main() {
  echo_info "This script can install Composer using either:"
  echo_note "1) Distribution APT repository (stable but not latest)."
  echo_note "2) Official Composer binary installer (always latest)."
  echo ""

  read -r -p "Choose installation method [1=APT / 2=Binary]: " choice
  case "$choice" in
    1) install_via_apt ;;
    2) install_via_binary ;;
    *) echo_error "Invalid choice"; exit 1 ;;
  esac

  # Print version once at the end (no duplicates)
  print_composer_version_once
}

main
