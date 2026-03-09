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
  echo_info "This installs MariaDB (server and client)."
  echo_info "MariaDB conflicts with MySQL."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  echo

  if apt_package_installed mariadb-server; then
    echo_success "MariaDB is already installed."
    if service_is_active mariadb; then
      echo
      echo_info "MariaDB service is running."
      exit 0
    else
      echo_info "Enabling MariaDB service..."
      service_enable_now mariadb
      service_status_line mariadb
      exit 0
    fi
  fi

  if apt_package_installed mysql-server || apt_package_installed mysql-community-server; then
    echo_error "MySQL is already installed. MariaDB conflicts with MySQL."
    exit 1
  fi

  apt_update
  apt_install mariadb-server mariadb-client
  service_enable_now mariadb
  echo
  if confirm "Do you want to run 'mysql_secure_installation' to secure your MariaDB installation now?"; then
    echo
    echo_info "Running 'mysql_secure_installation'..."
    sudo mysql_secure_installation
  else
    echo_info "You can run 'mysql_secure_installation' later to secure your MariaDB installation."
  fi 
  echo
  echo_success "MariaDB installed and started."
  service_status_line mariadb
}

main "$@"
