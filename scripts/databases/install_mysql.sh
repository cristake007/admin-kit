#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

MYSQL_LIST="/etc/apt/sources.list.d/mysql.list"
MYSQL_KEYRING="/usr/share/keyrings/mysql-apt.gpg"

main() {
  echo_info "This will install Oracle MySQL Server."
  echo_info "After installation, the MySQL service will be enabled and started."
  echo_info "The script will first detect if MariaDB is installed, as MySQL conflicts with MariaDB."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if apt_is_installed mysql-server || apt_is_installed mysql-community-server; then
    echo_success "MySQL is already installed."
    sudo systemctl enable --now mysql
    exit 0
  fi

  if apt_is_installed mariadb-server; then
    echo_error "MariaDB is already installed. MySQL conflicts with MariaDB."
    exit 1
  fi
  
  apt_update
  if ! apt_install mysql-server; then
    add_mysql_repo
    apt_update
    apt_install mysql-server
  fi

  sudo systemctl enable --now mysql
  echo_success "MySQL installed and started."
}

main
