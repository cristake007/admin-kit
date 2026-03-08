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

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_package_installed nginx; then
    echo_success "Nginx is already installed."
    service_enable_now nginx
    service_status_line nginx
    exit 0
  fi

  if apt_package_installed apache2; then
    echo_error "Apache is installed. Remove it before installing Nginx."
    exit 1
  fi

  echo_note "Installing nginx..."
  apt_update
  apt_install nginx
  service_enable_now nginx
  echo_success "Nginx installed."
  service_status_line nginx
}

main "$@"
