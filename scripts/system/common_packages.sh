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
  echo_info "Install minimal baseline packages (shared by most scripts)."
  echo_info "Includes: ca-certificates, curl, gnupg, lsb-release"
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }
  echo

  local packages=(curl wget git unzip zip ca-certificates curl gnupg lsb-release)
  local missing=()
  local pkg

  for pkg in "${packages[@]}"; do
    if apt_package_installed "$pkg"; then
      echo_info "Package already installed: $pkg"
    else
      missing+=("$pkg")
    fi
  done
  
  echo
  
  if [[ ${#missing[@]} -eq 0 ]]; then
    echo_success "All baseline packages are already installed."
    return 0
  fi
  
  echo_note "Updating package index..."
  apt_update

  echo_note "Installing missing packages: ${missing[*]}"
  apt_install "${missing[@]}"
  echo
  echo_success "Baseline packages installed successfully."
}
main "$@"
