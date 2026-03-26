#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

METHOD="apt"

composer_healthy() {
  command_exists composer || return 1
  COMPOSER_ALLOW_SUPERUSER=1 composer --version >/dev/null 2>&1
}

check_installed(){ composer_healthy; }
check_conflicts(){ return 0; }
install_step(){
  if [[ "$METHOD" == "apt" ]]; then
    apt_update
    if apt_package_installed composer && ! composer_healthy; then
      sudo apt-get install --reinstall -y composer php-composer-pcre
    else
      apt_install composer php-composer-pcre
    fi
  else
    command_exists php || { apt_update; apt_install php-cli; }
    command_exists curl || { apt_update; apt_install curl; }
    local expected_signature actual_signature
    expected_signature="$(curl -fsSL https://composer.github.io/installer.sig)" || return 1
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    actual_signature="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    [[ "$expected_signature" == "$actual_signature" ]] || { rm -f composer-setup.php; echo_error "Invalid installer signature."; return 1; }
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
    chmod +x /usr/local/bin/composer || true
  fi
  composer_healthy || { echo_error "Composer installation completed but command health check failed."; return 1; }
  wf_mark_changed "Installed Composer via ${METHOD}"
}
summary_step(){
  wf_default_summary "$1" "$2"
  if composer_healthy; then
    COMPOSER_ALLOW_SUPERUSER=1 composer --version 2>/dev/null | sed '/^Deprecated:/d' || true
  else
    echo_error "Composer command is present but unhealthy."
  fi
}

main(){
  local choice
  echo_info "Install Composer using APT (stable) or official binary (latest)."; echo_info "Enter 'q' to cancel."
  read -r -p "Choose installation method [1=APT / 2=Binary / q=Cancel]: " choice
  case "$choice" in
    1) METHOD="apt" ;;
    2) METHOD="binary" ;;
    [Qq]) echo_info "Composer installation cancelled."; exit 0 ;;
    *) echo_error "Invalid choice. Enter 1, 2, or q."; exit 1 ;;
  esac
  if ! run_install_workflow "composer" check_installed check_conflicts install_step summary_step; then
    exit 1
  fi
}
main "$@"
