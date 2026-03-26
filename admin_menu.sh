#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
trap err_trap ERR

run_action() {
  local script_path="$1"
  local header="$2"
  local fail_msg="$3"

  clear
  display_header "$header"
  run "$SCRIPT_DIR/$script_path" || echo_error "$fail_msg"
  pause
}

render_submenu() {
  local title="$1"
  shift
  local -a entries=("$@")

  while true; do
    local choice key label script header fail_msg

    clear
    display_header "$title"

    for entry in "${entries[@]}"; do
      IFS='|' read -r key label _ <<< "$entry"
      echo_note "$key) $label"
    done

    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    if ! read -r choice; then
      echo_info "Input closed. Returning to main menu."
      return
    fi

    if [[ "$choice" == "0" ]]; then
      return
    fi

    local matched=0
    for entry in "${entries[@]}"; do
      IFS='|' read -r key label script header fail_msg <<< "$entry"
      if [[ "$choice" == "$key" ]]; then
        matched=1
        run_action "$script" "$header" "$fail_msg"
        break
      fi
    done

    if [[ "$matched" -eq 0 ]]; then
      echo_error "Invalid option. Please try again."
      pause
    fi
  done
}

system_screen() {
  render_submenu "SYSTEM" \
    "1|System update and upgrade|scripts/system/update_system.sh|Update system|System update/upgrade failed." \
    "2|Create user with sudo privileges|scripts/system/create_user.sh|Create sudo user|User creation failed." \
    "3|Set timezone|scripts/system/set_timezone.sh|Set timezone|Setting timezone failed." \
    "4|Set hostname|scripts/system/set_hostname.sh|Set hostname|Setting hostname failed." \
    "5|Install common packages|scripts/system/common_packages.sh|Install common packages|Installing common packages failed."
}

webserver_screen() {
  render_submenu "WEBSERVER" \
    "1|Install Apache2|scripts/webserver/apache2.sh|Install Apache2|Apache2 setup failed." \
    "2|Install Nginx|scripts/webserver/nginx.sh|Install Nginx|Nginx install failed." \
    "3|Install Certbot (Let's Encrypt)|scripts/webserver/certbot.sh|Install Certbot|Certbot install failed."
}

databases_screen() {
  render_submenu "DATABASES" \
    "1|Install MariaDB|scripts/databases/install_mariadb.sh|Install MariaDB|MariaDB setup failed." \
    "2|Install MySQL|scripts/databases/install_mysql.sh|Install MySQL|MySQL install failed." \
    "3|Install PostgreSQL|scripts/databases/install_postgresql.sh|Install PostgreSQL|PostgreSQL install failed."
}

security_screen() {
  render_submenu "SECURITY" \
    "1|Disable root SSH login|scripts/security/ssh_disable_root.sh|Disable root SSH login|SSH root login config failed." \
    "2|Install fail2ban|scripts/security/install_fail2ban.sh|Install Fail2Ban|Fail2ban install failed." \
    "3|Install UFW|scripts/security/install_ufw.sh|Install UFW|UFW install failed."
}

developer_screen() {
  render_submenu "DEVELOPER TOOLS" \
    "1|Install Extrepo (external apt repositories)|scripts/developer/install_extrepo.sh|Install Extrepo|Extrepo install failed." \
    "2|Install PHP and common extensions|scripts/developer/install_php.sh|Install PHP and extensions|PHP install failed." \
    "3|Install Composer|scripts/developer/install_composer.sh|Install Composer|Composer install failed." \
    "4|Install Node.js and npm|scripts/developer/install_nodejs.sh|Install Node.js and npm|Node.js install failed." \
    "5|Install Symfony CLI|scripts/developer/install_symfony.sh|Install Symfony CLI|Symfony install failed." \
    "6|Install Docker CE|scripts/developer/install_docker.sh|Install Docker CE|Docker install failed." \
    "7|Install RabbitMQ|scripts/developer/install_rabbitmq.sh|Install RabbitMQ|RabbitMQ install failed." \
    "8|Install Valkey|scripts/developer/install_valkey.sh|Install Valkey|Valkey install failed." \
    "9|Manage environment file (.env)|scripts/helper/env_manager.sh|Environment manager|.env manager failed."
}

custom_screen() {
  render_submenu "CUSTOM SCRIPTS" \
    "1|Quick install ILIAS LMS|scripts/custom/ilias.sh|Quick install ILIAS LMS|ILIAS install failed." \
    "2|Install Apache+PHP required packages|scripts/custom/apache_php_required_packages.sh|Apache+PHP required packages|Apache/PHP requirements failed." \
    "3|Create ILIAS directories|scripts/custom/create_directories.sh|Create ILIAS directories|Directory creation failed." \
    "4|Install ILIAS system required packages|scripts/custom/system_required_packages.sh|System required packages|System package install failed."
}

backups_screen() {
  clear
  display_header "BACKUPS"
  echo_note "Backup functionality is under development."
  pause
}

while true; do
  clear
  display_header "SYSTEM ADMINISTRATION MENU"
  echo_note "1) SYSTEM"
  echo_note "2) WEBSERVER PACKAGES (APACHE/NGINX)"
  echo_note "3) DATABASE SERVERS (MYSQL/MARIADB/POSTGRESQL)"
  echo_note "4) SERVER HARDENING"
  echo_note "5) BACKUPS"
  echo_note "6) DEVELOPER TOOLS"
  echo_note "7) CUSTOM SCRIPTS"
  echo_note ""
  echo_note "------------------------------------------------"
  echo_note "0) EXIT"
  echo -ne "\n${YELLOW}Enter your choice:${NC} "

  if ! read -r main_choice; then
    echo_info "Input closed. Exiting."
    exit 0
  fi

  case "$main_choice" in
    1) system_screen ;;
    2) webserver_screen ;;
    3) databases_screen ;;
    4) security_screen ;;
    5) backups_screen ;;
    6) developer_screen ;;
    7) custom_screen ;;
    0) clear; echo_success "Thank you for using the System Administration Menu."; exit 0 ;;
    *) echo_error "Invalid option. Please try again."; pause ;;
  esac
done
