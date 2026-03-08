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
  echo_info "This installs Symfony CLI."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if command_exists symfony; then
    echo_success "Symfony CLI already installed: $(symfony -V | head -n1)"
    exit 0
  fi

  apt_update
  apt_install ca-certificates curl gnupg
  curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
  apt_update
  apt_install symfony-cli

  echo_success "Symfony CLI installed: $(symfony -V | head -n1)"
}

main "$@"
