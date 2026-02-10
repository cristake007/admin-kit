#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

echo_info "This script installs the 'extrepo' package to manage external repositories."

if confirm "Do you want to continue?"; then
  echo_info "Proceeding with extrepo installation..."
else
  echo_info "Installation cancelled by user."
  exit 0
fi

main() {
  if apt_is_installed extrepo; then
    echo_info "extrepo is already installed."
  else
    echo_note "Installing extrepo..."
    apt_update
    apt_install extrepo
    echo_success "Extrepo installed."
  fi

  # Optional: show version if available
  if command -v extrepo >/dev/null 2>&1; then
    dpkg -s extrepo | awk -F': ' '/^Version:/ {printf "Extrepo %s %s\n", $1, $2}'
  fi
}

main
