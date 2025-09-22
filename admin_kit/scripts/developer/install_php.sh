#!/usr/bin/env bash
set -euo pipefail

# Self-bootstrap (works no matter where you run it from)
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  local default_ver="8.2"
  local versions=("$default_ver")
  
  # If extrepo is installed, add other versions
  if command_exists extrepo; then
    # Common versions from Sury repo (Debian + extrepo)
    versions+=("7.4" "8.1" "8.3" "8.4")
  fi

  echo_info "If you dont see your desired version, please install extrepo first."
  echo_info "Available PHP versions to install:"
  for i in "${!versions[@]}"; do
    local label="${versions[$i]}"
    if [[ "$label" == "$default_ver" ]]; then
      echo_note "$((i+1))) PHP ${label} (Debian default)"
    else
      echo_note "$((i+1))) PHP ${label} (via extrepo)"
    fi
  done
  
  # Add go back option
  echo_note "0) Go back"

  echo -ne "\nEnter your choice [1, 0=Back]: "
  read -r choice
  choice="${choice:-1}"

  # Handle go back
  if [[ "$choice" == "0" ]]; then
    return 0   # or exit 0 if not in a function
  fi

  # Validate numeric selection
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#versions[@]} )); then
    echo_error "Invalid selection."
    return 1   # or exit 1, depending on your menu structure
  fi

  local PHP_VERSION="${versions[$((choice-1))]}"
  echo_info "Selected PHP version: ${PHP_VERSION}"

  # Already installed?
  if command_exists php; then
    local current_version
    current_version="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
    if [[ "$current_version" == "$PHP_VERSION" ]]; then
      echo_success "PHP ${current_version} is already installed."
      php -v | head -n1
      exit 0
    fi
    echo_note "Different PHP version (${current_version}) already installed."
  fi

  if [[ "$PHP_VERSION" == "$default_ver" ]]; then
    echo_note "Installing PHP ${PHP_VERSION} from Debian repository..."
    apt_update
    apt_install php php-cli php-common php-mysql php-xml php-curl php-zip php-gd php-mbstring
  else
    if ! command_exists extrepo; then
      echo_error "extrepo is not installed. Please run the 'Install Extrepo' option from the menu first."
      exit 1
    fi

    echo_note "Enabling Sury PHP repository with extrepo..."
    sudo extrepo enable sury

    echo_note "Refreshing apt metadata..."
    apt_update
    
    if confirm "Do you wish to install common PHP extensions along with PHP ${PHP_VERSION}?"; then
      echo_note "Installing PHP ${PHP_VERSION} and common extensions..."
      apt_install "php${PHP_VERSION}" \
                  "php${PHP_VERSION}-cli" \
                  "php${PHP_VERSION}-common" \
                  "php${PHP_VERSION}-mysql" \
                  "php${PHP_VERSION}-xml" \
                  "php${PHP_VERSION}-curl" \
                  "php${PHP_VERSION}-zip" \
                  "php${PHP_VERSION}-gd" \
                  "php${PHP_VERSION}-mbstring"
      update-alternatives --config php
    else
      echo_note "Will install only the base PHP package."
    fi
    
  fi

  echo_success "PHP ${PHP_VERSION} installed successfully."
  php -v | head -n1 || true
}

main