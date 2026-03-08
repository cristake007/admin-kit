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
  echo_info "This script updates package lists and can run dist-upgrade."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  apt_update
  echo_success "Package lists updated."

  if confirm "Upgrade packages now?"; then
    echo_info "Upgrading packages (dist-upgrade)..."
    apt_upgrade
    echo_success "Upgrade completed."
  else
    echo_info "Upgrade skipped."
  fi
}

main "$@"
