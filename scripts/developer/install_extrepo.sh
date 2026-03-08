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
  echo_info "This installs 'extrepo' for managing external APT repositories."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_is_installed extrepo; then
    echo_info "extrepo is already installed."
  else
    apt_update
    apt_install extrepo
    echo_success "extrepo installed."
  fi

  dpkg -s extrepo 2>/dev/null | awk -F': ' '/^Version:/ {print "extrepo version: " $2}' || true
}

main "$@"
