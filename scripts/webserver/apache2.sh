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
  echo_info "This installs Apache2."
  echo_info "Apache and Nginx conflict on ports 80/443."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_is_installed apache2; then
    echo_success "Apache2 is already installed."
    service_enable_now apache2
    service_status_line apache2
    exit 0
  fi

  if apt_is_installed nginx; then
    echo_error "Nginx is installed. Remove it before installing Apache2."
    exit 1
  fi

  echo_note "Installing apache2..."
  apt_update
  apt_install apache2
  service_enable_now apache2
  echo_success "Apache2 installed."
  service_status_line apache2
}

main "$@"
