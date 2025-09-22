#!/usr/bin/env bash
set -Euo pipefail
trap err_trap ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Bootstrap + functions
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require "functions/functions.sh"

###################
#      SYSTEM     #
###################
system_screen() {
  while true; do
    clear
    display_header "SYSTEM"
    echo_note "1) System update and upgrade"
    echo_note "2) Create user with sudo privileges"
    echo_note "3) Set timezone"
    echo_note "4) Set hostname"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Updating system"
        bash "$SCRIPT_DIR/scripts/system/update_system.sh" || echo_error "System update/upgrade failed."; pause;;
      2)
        clear
        display_header "Create sudo user"
        bash "$SCRIPT_DIR/scripts/system/create_user.sh" || echo_error "User creation failed."; pause;;
      3)
        clear
        display_header "Setting timezone"
        bash "$SCRIPT_DIR/scripts/system/set_timezone.sh" || echo_error "Setting timzone failed."; pause;;
      4)
        clear
        display_header "Set hostname"
        bash "$SCRIPT_DIR/scripts/system/set_hostname.sh" || echo_error "Setting hostname failed."; pause;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}


###################
#    WEBSERVER    #
###################
webserver_screen() {
  while true; do
    clear
    display_header "Webserver"
    echo_note "1) Install Apache2"
    echo_note "2) Install Nginx"
    echo_note "3) Install Certbot (Let's Encrypt)"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Install Apache2"
        run "$SCRIPT_DIR/scripts/webserver/apache2.sh" || echo_error "Apache2 setup failed failed."; pause ;;
      2)
        clear
        display_header "Install Nginx"
        run "$SCRIPT_DIR/scripts/webserver/nginx.sh" || echo_error "Nginx install failed."; pause ;;
      3)
        clear
        display_header "Install Certbot"
        run "$SCRIPT_DIR/scripts/webserver/certbot.sh" || echo_error "Certbot install failed."; pause ;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}


###################
#    DATABASES    #
###################
databases_screen() {
  while true; do
    clear
    display_header "Databases"
    echo_note "1) Install MariaDB"
    echo_note "2) Install MySQL"
    echo_note "3) Install PostgreSQL"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Install MariaDB"
        run "$SCRIPT_DIR/scripts/databases/install_mariadb.sh" || echo_error "MariaDB setup failed failed."; pause ;;
      2)
        clear
        display_header "Install MySQL"
        run "$SCRIPT_DIR/scripts/databases/install_mysql.sh" || echo_error "MySQL install failed."; pause ;;
      3)
        clear
        display_header "Install PostgreSQL"
        run "$SCRIPT_DIR/scripts/databases/install_postgresql.sh" || echo_error "PostgreSQL install failed."; pause ;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}


###################
#     SECURITY    #
###################
security_screen() {
  while true; do
    clear
    display_header "Security"
    echo_note "1) Disable root SSH login"
    echo_note "2) Install fail2ban"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Disable root SSH login"
        run "$SCRIPT_DIR/scripts/security/ssh_disable_root.sh" || echo_error "SSH root login config failed."; pause ;;
      2)
        clear
        display_header "Install Fail2Ban"
        run "$SCRIPT_DIR/scripts/security/install_fail2ban.sh" || echo_error "Fail2ban install failed."; pause ;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}

backups_screen(){
  echo_error "Backup functionality is under development."
  while true; do
    clear
    display_header "Backups"
    echo_note "1) Backup script --in development"
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Backup script"
        echo_info "This feature is under development."; pause ;;

      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}

developer_screen(){
  while true; do
    clear
    display_header "Developer tools"
    echo_note "1) Install Extrepo (external apt repositories)"
    echo_note "2) Install PHP and common extensions"
    echo_note "3) Install Composer"
    echo_note "4) Install Node.js and npm"
    #echo_note "5) Install Python and pip"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Install EXTREPO"
        run "$SCRIPT_DIR/scripts/developer/install_extrepo.sh" || echo_error "Extrepo install failed."; pause ;;
      2)
        clear
        display_header "Install PHP and common extensions"
        run "$SCRIPT_DIR/scripts/developer/install_php.sh" || echo_error "PHP install failed."; pause ;;
      3)
        clear
        display_header "Composer (PHP dependency manager)"
        run "$SCRIPT_DIR/scripts/developer/install_composer.sh" || echo_error "Composer install failed."; pause ;;
      4)
        clear
        display_header "Install Node.js and npm"
        run "$SCRIPT_DIR/scripts/developer/install_nodejs.sh" || echo_error "Node.js install failed."; pause ;;
      # 5)
      #   clear
      #   display_header "Install Python and pip"
      #   run "$SCRIPT_DIR/scripts/helper/install_pypip.sh" || echo_error "Pyhton install failed."; pause;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
}

custom_screen(){
  while true; do
    clear
    display_header "Custom scripts"
    echo_note "1) Custom Quick Install ILIAS LMS"
    echo_note ""
    echo_note "0) Return to Main Menu"
    echo -ne "\n${YELLOW}Enter your choice:${NC} "
    read -r choice

    case "$choice" in
      1)
        clear
        display_header "Custom Quick Install ILIAS LMS"
        run "$SCRIPT_DIR/scripts/custom/ilias.sh" || echo_error "Ilias install failed."; pause;;
      0) return ;;
      *) echo_error "Invalid option. Please try again."; pause ;;
    esac
  done
} 

###################
#   MAIN MENU     #
###################
while true; do
  clear
  display_header "SYSTEM ADMINISTRATION MENU"
  echo_note "1) System"
  echo_note "2) Webserver packages (Apache/Nginx)"
  echo_note "3) Database servers (MySQL/MariaDB/PostgreSQL)"
  echo_note "4) Server hardening"
  echo_note "5) Backups --in development"
  echo_note "6) Developer Tools (Node.js, Composer, PHP, Python, etc.) --in development"
  echo_note "7) Custom scripts --in development"
  echo_note ""
  echo_note "------------------------------------------------"
  echo_note "0) Exit"
  echo -ne "\n${YELLOW}Enter your choice:${NC} "
  read -r main_choice

  case "$main_choice" in
    1) system_screen ;;
    2) webserver_screen ;;
    3) databases_screen ;;
    4) security_screen ;;
    5) backups_screen ;;
    6) developer_screen ;;
    7) custom_screen ;;
    0) clear; echo_success "Thank you for using the System Administration Menu."; exit 0 ;;
    *) echo_error "Invalid option. Please try again."; sleep 1 ;;
  esac
done