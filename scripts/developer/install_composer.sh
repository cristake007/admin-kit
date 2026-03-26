#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
trap err_trap ERR

need_sudo || exit 1

install_via_apt() {
  apt_update
  if apt_package_installed composer; then
    echo_success "Composer is already installed via APT."
  else
    apt_install composer
    echo_success "Composer installed (APT)."
  fi
}

install_via_binary() {
  command_exists php || { apt_update; apt_install php-cli; }
  command_exists curl || { apt_update; apt_install curl; }

  if item_is_installed composer; then
    echo_info "Composer is already present."
    return 0
  fi

  local expected_signature actual_signature rc
  expected_signature="$(curl -fsSL https://composer.github.io/installer.sig)" || { echo_error "Could not fetch installer signature."; return 1; }
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" || { echo_error "Could not download installer."; return 1; }
  actual_signature="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [[ "$expected_signature" != "$actual_signature" ]]; then
    echo_error "Invalid installer signature."
    rm -f composer-setup.php
    return 1
  fi

  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rc=$?
  rm -f composer-setup.php
  (( rc == 0 )) || return "$rc"
  chmod +x /usr/local/bin/composer || true
  echo_success "Composer installed (binary)."
}

main() {
  local choice
  echo_info "Install Composer using APT (stable) or official binary (latest)."

  while true; do
    read -r -p "Choose installation method [1=APT / 2=Binary]: " choice
    case "$choice" in
      1) install_via_apt; break ;;
      2) install_via_binary; break ;;
      *)
        echo_error "Invalid choice. Please enter 1 (APT) or 2 (Binary)."
        ;;
    esac
  done

  echo_note "Composer version:"
  if command_exists composer; then
    if id -u www-data >/dev/null 2>&1; then
      sudo -u www-data composer --version 2>/dev/null || composer --version 2>/dev/null || true
    else
      composer --version 2>/dev/null || true
    fi
    echo_success "Composer is ready to use."
  else
    echo_error "Composer command not found after installation."
    exit 1
  fi
}

main "$@"
