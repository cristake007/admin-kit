#!/usr/bin/env bash
# Metadata:
# Requires: apt, optional extrepo for non-default versions
# Privileges: root or sudo
# Target distro: Debian/Ubuntu
# Side effects: installs PHP packages and may change active php alternative
# Safe to re-run: yes
set -euo pipefail

# Self-bootstrap (works no matter where you run it from)
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

has_extrepo() {
  apt_is_installed extrepo || command_exists extrepo
}

install_php_packages() {
  local version="$1"
  local with_extensions="$2"

  local packages=("php${version}" "php${version}-cli" "php${version}-common")
  if [[ "$with_extensions" == "yes" ]]; then
    packages+=(
      "php${version}-mysql"
      "php${version}-xml"
      "php${version}-curl"
      "php${version}-zip"
      "php${version}-gd"
      "php${version}-mbstring"
    )
  fi

  echo_note "Installing: ${packages[*]}"
  apt_install "${packages[@]}"
}

set_php_alternative() {
  local version="$1"
  local php_bin="/usr/bin/php${version}"

  if [[ -x "$php_bin" ]]; then
    sudo update-alternatives --set php "$php_bin"
    echo_note "Set active CLI PHP to $php_bin"
  else
    echo_info "Could not find $php_bin for update-alternatives."
  fi
}

main() {
  local default_ver="8.2"
  local versions=("$default_ver")

  # If extrepo is installed, add other versions
  if has_extrepo; then
    # Common versions from Sury repo (Debian + extrepo)
    versions+=("7.4" "8.1" "8.3" "8.4")
  fi

  echo_info "If you don't see your desired version, install extrepo first."
  echo_info "Available PHP versions to install:"
  for i in "${!versions[@]}"; do
    local label="${versions[$i]}"
    if [[ "$label" == "$default_ver" ]]; then
      echo_note "$((i + 1))) PHP ${label} (Debian default)"
    else
      echo_note "$((i + 1))) PHP ${label} (via extrepo/Sury)"
    fi
  done
  echo_note "0) Go back"

  echo -ne "\nEnter your choice [1, 0=Back]: "
  read -r choice
  choice="${choice:-1}"

  if [[ "$choice" == "0" ]]; then
    return 0
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#versions[@]})); then
    echo_error "Invalid selection."
    return 1
  fi

  local php_version="${versions[$((choice - 1))]}"
  echo_info "Selected PHP version: ${php_version}"

  if command_exists php; then
    local current_version
    current_version="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)"
    if [[ -n "$current_version" && "$current_version" == "$php_version" ]]; then
      echo_success "PHP ${current_version} is already the active CLI version."
      php -v | head -n1
      return 0
    fi

    if [[ -n "$current_version" ]]; then
      echo_note "Current active CLI PHP version is ${current_version}."
      if ! confirm "Continue with installing/switching to PHP ${php_version}?"; then
        echo_info "Cancelled."
        return 0
      fi
    fi
  fi

  local with_extensions="yes"
  if ! confirm "Install common PHP extensions with PHP ${php_version}?"; then
    with_extensions="no"
  fi

  apt_update

  if [[ "$php_version" == "$default_ver" ]]; then
    # Debian default package naming is unversioned on many systems.
    local packages=(php php-cli php-common)
    if [[ "$with_extensions" == "yes" ]]; then
      packages+=(php-mysql php-xml php-curl php-zip php-gd php-mbstring)
    fi
    echo_note "Installing PHP ${php_version} from Debian repository..."
    echo_note "Installing: ${packages[*]}"
    apt_install "${packages[@]}"
  else
    if ! has_extrepo; then
      echo_error "extrepo is not installed. Run the 'Install Extrepo' menu option first."
      return 1
    fi

    echo_note "Enabling Sury PHP repository with extrepo..."
    sudo extrepo enable sury
    apt_update

    install_php_packages "$php_version" "$with_extensions"
  fi

  set_php_alternative "$php_version"

  echo_success "PHP ${php_version} installation completed."
  php -v | head -n1 || true
}

main
