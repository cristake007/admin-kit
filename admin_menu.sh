#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require_lib log
require_lib ui
require_lib core

run_and_pause() {
  local rel_script="$1"
  if run_script "$rel_script"; then
    success "Done: $rel_script"
  else
    error "Failed: $rel_script"
  fi
  pause
}

system_menu() {
  while true; do
    clear
    display_header "System"
    echo "1) Update system"
    echo "2) Create privileged user"
    echo "3) Set timezone"
    echo "4) Set hostname"
    echo "5) Install common packages"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/system/update_system.sh ;;
      2) run_and_pause scripts/system/create_user.sh ;;
      3) run_and_pause scripts/system/set_timezone.sh ;;
      4) run_and_pause scripts/system/set_hostname.sh ;;
      5) run_and_pause scripts/system/common_packages.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

webserver_menu() {
  while true; do
    clear
    display_header "Webserver"
    echo "1) Install Apache"
    echo "2) Install Nginx"
    echo "3) Install Certbot"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/webserver/apache2.sh ;;
      2) run_and_pause scripts/webserver/nginx.sh ;;
      3) run_and_pause scripts/webserver/certbot.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

database_menu() {
  while true; do
    clear
    display_header "Databases"
    echo "1) Install MariaDB"
    echo "2) Install MySQL"
    echo "3) Install PostgreSQL"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/databases/install_mariadb.sh ;;
      2) run_and_pause scripts/databases/install_mysql.sh ;;
      3) run_and_pause scripts/databases/install_postgresql.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

security_menu() {
  while true; do
    clear
    display_header "Security"
    echo "1) Disable SSH root login"
    echo "2) Install fail2ban"
    echo "3) Install firewall tooling"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/security/ssh_disable_root.sh ;;
      2) run_and_pause scripts/security/install_fail2ban.sh ;;
      3) run_and_pause scripts/security/install_ufw.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

developer_menu() {
  while true; do
    clear
    display_header "Developer"
    echo "1) Install extrepo"
    echo "2) Install PHP"
    echo "3) Install Composer"
    echo "4) Install Node.js"
    echo "5) Install Symfony prerequisites"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/developer/install_extrepo.sh ;;
      2) run_and_pause scripts/developer/install_php.sh ;;
      3) run_and_pause scripts/developer/install_composer.sh ;;
      4) run_and_pause scripts/developer/install_nodejs.sh ;;
      5) run_and_pause scripts/developer/install_symfony.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

custom_menu() {
  while true; do
    clear
    display_header "Custom"
    echo "1) ILIAS baseline workflow"
    echo "0) Back"
    read -r -p "Choice: " choice
    case "$choice" in
      1) run_and_pause scripts/custom/ilias.sh ;;
      0) return ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

main() {
  while true; do
    clear
    display_header "Admin Kit"
    echo "1) System"
    echo "2) Webserver"
    echo "3) Databases"
    echo "4) Security"
    echo "5) Developer"
    echo "6) Custom"
    echo "0) Exit"
    read -r -p "Choice: " choice
    case "$choice" in
      1) system_menu ;;
      2) webserver_menu ;;
      3) database_menu ;;
      4) security_menu ;;
      5) developer_menu ;;
      6) custom_menu ;;
      0) exit 0 ;;
      *) warn "Invalid option"; pause ;;
    esac
  done
}

main "$@"
