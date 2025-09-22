#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This will install MariaDB (server & client)."
  echo_info "After installation, the MariaDB service will be enabled and started."
  echo_info "The script will first detect if MySQL is installed, as MariaDB conflicts with MySQL."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if apt_is_installed mariadb-server; then
    echo_success "MariaDB is already installed."
    sudo systemctl enable --now mariadb
    exit 0
  fi

  if apt_is_installed mysql-server || apt_is_installed mysql-community-server; then
    echo_error "MySQL is already installed. MariaDB conflicts with MySQL."
    exit 1
  fi

  apt_update
  apt_install mariadb-server mariadb-client
  sudo systemctl enable --now mariadb
  echo_info "Securing MariaDB installation..."
  sudo mysql_secure_installation
  echo_success "MariaDB installed and started."
}

main
