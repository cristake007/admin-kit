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
  echo_info "This installs Nginx."
  echo_info "Apache and Nginx conflict on ports 80/443."
  echo

  if apt_package_installed nginx; then
    echo_success "Nginx is already installed."
    service_enable_now nginx
    service_status_line nginx
    exit 0
  fi

  if apt_package_installed apache2; then
    echo_error "Cannot install Nginx while Apache is installed."
    echo_note "Next steps:"
    echo_note "  1) Run the Apache uninstall/disable flow first."
    echo_note "  2) Re-run this Nginx installer."
    exit 0
  fi

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  echo_note "Installing nginx..."
  apt_update
  apt_install nginx
  service_enable_now nginx
  if ! service_is_active nginx; then
    echo_error "Nginx package installed, but service is not active."
    service_status_line nginx
    exit 1
  fi

  echo_success "Nginx installed and running."
  service_status_line nginx
}

main "$@"
