#!/usr/bin/env bash
# Metadata:
# Requires: apt, dpkg
# Privileges: root or sudo
# Target distro: Debian/Ubuntu
# Side effects: installs baseline system packages
# Safe to re-run: yes
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"
trap 'err_trap' ERR

need_sudo || exit 1

main() {
  local packages=(
    ca-certificates
    curl
    gnupg
    lsb-release
  )

  echo_info "Install minimal baseline packages (shared by most scripts)."
  show_script_metadata \
    "apt, dpkg" \
    "root or sudo" \
    "Debian/Ubuntu" \
    "installs baseline system packages" \
    "yes"
  echo_note "Managed baseline package set: ${packages[*]}"
  echo

  local already_installed=()
  local missing=()
  local pkg

  for pkg in "${packages[@]}"; do
    if apt_is_installed "$pkg"; then
      already_installed+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  echo_note "Current state: ${#already_installed[@]}/${#packages[@]} packages installed."
  if [[ ${#already_installed[@]} -gt 0 ]]; then
    echo_note "Already installed: ${already_installed[*]}"
  fi

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo_success "All baseline packages are already installed. Nothing to do."
    return 0
  fi

  echo_note "Missing packages: ${missing[*]}"
  confirm "Install missing baseline packages now?" || { echo_info "Cancelled."; exit 0; }

  echo_note "Updating package index..."
  apt_update

  echo_note "Installing missing packages..."
  apt_install "${missing[@]}"

  echo_success "Baseline packages installed successfully."
  echo_note "Post-check:"
  for pkg in "${packages[@]}"; do
    if apt_is_installed "$pkg"; then
      echo_note "  - $pkg [installed]"
    else
      echo_error "  - $pkg [missing]"
    fi
  done
}

main "$@"
