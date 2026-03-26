#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

PHP_VERSION="8.2"
DEFAULT_VER="8.2"
check_installed(){ command_exists php && [[ "$(php -r 'echo PHP_MAJOR_VERSION"."PHP_MINOR_VERSION;' 2>/dev/null || true)" == "$PHP_VERSION" ]]; }
check_conflicts(){ [[ "$PHP_VERSION" == "$DEFAULT_VER" ]] && return 0; command_exists extrepo || { echo_error "extrepo is required for PHP ${PHP_VERSION}."; return 1; }; }
install_step(){
  if [[ "$PHP_VERSION" == "$DEFAULT_VER" ]]; then
    apt_update; apt_install php php-cli php-common php-mysql php-xml php-curl php-zip php-gd php-mbstring
  else
    sudo extrepo enable sury; apt_update
    if confirm "Install common PHP extensions with PHP ${PHP_VERSION}?"; then
      apt_install "php${PHP_VERSION}" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-common" "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-curl" "php${PHP_VERSION}-zip" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-mbstring"
    else
      apt_install "php${PHP_VERSION}"
    fi
  fi
  wf_mark_changed "Installed PHP ${PHP_VERSION}"
}
summary_step(){ wf_default_summary "$1" "$2"; php -v | head -n1 || true; }

main(){
  local versions=("$DEFAULT_VER") choice
  echo_info "Install PHP and optionally common extensions."
  command_exists extrepo && versions+=("7.4" "8.1" "8.3" "8.4")
  echo_note "Available PHP versions:"; for i in "${!versions[@]}"; do echo_note "$((i+1))) PHP ${versions[$i]}"; done; echo_note "0) Cancel"
  read -r -p "Enter your choice [1]: " choice; choice="${choice:-1}"; [[ "$choice" == "0" ]] && { echo_info "Cancelled."; exit 0; }
  [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#versions[@]} )) || { echo_error "Invalid selection."; exit 1; }
  PHP_VERSION="${versions[$((choice-1))]}"
  run_install_workflow "php" check_installed check_conflicts install_step summary_step
}
main "$@"
