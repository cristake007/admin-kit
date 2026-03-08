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

main() {
  local default_ver="8.2"
  local versions=("$default_ver")
  local choice php_version current_version

  echo_info "Install PHP and optionally common extensions."

  if command_exists extrepo; then
    versions+=("7.4" "8.1" "8.3" "8.4")
  fi

  echo_note "Available PHP versions:"
  for i in "${!versions[@]}"; do
    echo_note "$((i+1))) PHP ${versions[$i]}"
  done
  echo_note "0) Cancel"

  read -r -p "Enter your choice [1]: " choice
  choice="${choice:-1}"
  [[ "$choice" == "0" ]] && { echo_info "Cancelled."; exit 0; }

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#versions[@]} )); then
    echo_error "Invalid selection."
    exit 1
  fi

  php_version="${versions[$((choice-1))]}"
  echo_info "Selected PHP version: ${php_version}"

  if command_exists php; then
    current_version="$(php -r 'echo PHP_MAJOR_VERSION"."PHP_MINOR_VERSION;' 2>/dev/null || true)"
    if [[ "$current_version" == "$php_version" ]]; then
      echo_success "PHP ${current_version} is already installed."
      php -v | head -n1
      exit 0
    fi
    [[ -n "$current_version" ]] && echo_note "Detected existing PHP version: ${current_version}"
  fi

  if [[ "$php_version" == "$default_ver" ]]; then
    apt_update
    apt_install php php-cli php-common php-mysql php-xml php-curl php-zip php-gd php-mbstring
  else
    command_exists extrepo || { echo_error "extrepo is required for PHP ${php_version}."; exit 1; }
    sudo extrepo enable sury
    apt_update

    if confirm "Install common PHP extensions with PHP ${php_version}?"; then
      apt_install "php${php_version}" "php${php_version}-cli" "php${php_version}-common" \
                  "php${php_version}-mysql" "php${php_version}-xml" "php${php_version}-curl" \
                  "php${php_version}-zip" "php${php_version}-gd" "php${php_version}-mbstring"
      update-alternatives --config php
    else
      apt_install "php${php_version}"
    fi
  fi

  echo_success "PHP ${php_version} installed successfully."
  php -v | head -n1 || true
}

main "$@"
