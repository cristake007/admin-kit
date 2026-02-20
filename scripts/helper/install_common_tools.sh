#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

echo_info "This script installs common command-line tools: curl, wget, git, unzip, zip, ufw, ca-certificates, gnupg, acl."

if confirm "Do you want to continue?"; then
  echo_info "Proceeding with installation..."
else
  echo_info "Installation cancelled by user."
  exit 0
fi

main() {
  local pkgs=(curl wget git unzip zip ufw ca-certificates gnupg acl)
  local missing=()

  echo_info "This will install: ${pkgs[*]}"

  # Collect missing packages
  for p in "${pkgs[@]}"; do
    if apt_is_installed "$p"; then
      echo_note "$p is already installed."
    else
      missing+=("$p")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo_success "All common tools are already installed."
    return 0
  fi

  echo_note "Updating apt metadata..."
  apt_update

  echo_note "Installing missing packages: ${missing[*]}"
  apt_install "${missing[@]}"

  echo_success "Common tools installed successfully."
}

main
