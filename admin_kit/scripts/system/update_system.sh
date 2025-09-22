#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main(){
  echo_info "This script updates the package lists, upgrades installed packages,"
  echo_info "and performs a distribution upgrade to ensure your system is up-to-date."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  apt_update

  echo
  if confirm "Upgrade packages now?"; then
    echo_info "Upgrading packages (dist-upgrade)..."
    apt_upgrade
    echo_success "Upgrade completed."
  else
    echo_info "Upgrade skipped."
  fi
}

main