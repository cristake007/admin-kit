#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/service.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  echo_info "This installs PostgreSQL (Debian default packages)."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_is_installed postgresql; then
    echo_success "PostgreSQL is already installed."
    service_enable_now postgresql
    service_status_line postgresql
    pg_config --version || true
    exit 0
  fi

  apt_update
  apt_install postgresql postgresql-client
  service_enable_now postgresql
  echo_success "PostgreSQL installed and started."
  service_status_line postgresql
  pg_config --version || true
}

main "$@"
