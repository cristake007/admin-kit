#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"
trap 'err_trap' ERR

need_sudo || exit 1

main() {
  echo_info "Install minimal baseline packages (shared by most scripts)."
  echo_info "Includes: ca-certificates, curl, gnupg, lsb-release"
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  local packages=(
    ca-certificates
    curl
    gnupg
    lsb-release
  )

  echo_note "Updating package index..."
  apt_update

  echo_note "Installing packages..."
  local pkg
  for pkg in "${packages[@]}"; do
    apt_install "$pkg"
  done

  echo_success "Baseline packages installed successfully."
}

main "$@"
