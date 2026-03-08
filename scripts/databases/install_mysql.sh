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
  echo_info "This installs Oracle MySQL Server."
  echo_info "MySQL conflicts with MariaDB."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_package_installed mysql-server || apt_package_installed mysql-community-server; then
    echo_success "MySQL is already installed."
    service_enable_now mysql
    service_status_line mysql
    exit 0
  fi

  if apt_package_installed mariadb-server; then
    echo_error "MariaDB is already installed. MySQL conflicts with MariaDB."
    exit 1
  fi

  apt_update
  if ! apt_install mysql-server; then
    add_mysql_repo
    apt_update
    apt_install mysql-server
  fi

  service_enable_now mysql
  echo_success "MySQL installed and started."
  service_status_line mysql
}

main "$@"
