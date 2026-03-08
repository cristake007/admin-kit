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
  echo_info "This installs Certbot for Apache or Nginx."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  detect_server || exit 1
  echo_info "Using web server: ${SERVER}"

  if apt_is_installed certbot; then
    echo_info "Certbot is already installed."
  else
    apt_update
    apt_install certbot
  fi

  if [[ "$SERVER" == "apache" ]]; then
    apt_is_installed python3-certbot-apache || apt_install python3-certbot-apache
    service_enable_now apache2 || true
    service_status_line apache2
  else
    apt_is_installed python3-certbot-nginx || apt_install python3-certbot-nginx
    service_enable_now nginx || true
    service_status_line nginx
  fi

  configure_firewall
  maybe_run_certbot_now
  echo_success "Certbot setup for ${SERVER} completed."
}

detect_server() {
  local has_apache=1 has_nginx=1
  if apt_is_installed apache2 || service_is_active apache2; then has_apache=0; fi
  if apt_is_installed nginx || service_is_active nginx; then has_nginx=0; fi

  if (( has_apache != 0 && has_nginx != 0 )); then
    echo_error "No supported webserver detected. Install Apache or Nginx first."
    return 1
  fi

  if (( has_apache == 0 && has_nginx == 0 )); then
    while true; do
      read -r -p "Use Certbot with which server? [a=Apache / n=Nginx]: " sel
      case "$sel" in
        a|A) SERVER="apache"; break ;;
        n|N) SERVER="nginx"; break ;;
        *) echo_error "Please choose 'a' or 'n'." ;;
      esac
    done
  elif (( has_apache == 0 )); then
    SERVER="apache"
  else
    SERVER="nginx"
  fi
}

configure_firewall() {
  if command_exists ufw; then
    echo_note "Ensuring UFW allows HTTP/HTTPS..."
    sudo ufw allow 80/tcp || true
    sudo ufw allow 443/tcp || true
    sudo ufw reload || true
  fi
}

maybe_run_certbot_now() {
  local flag
  [[ "$SERVER" == "apache" ]] && flag="--apache" || flag="--nginx"

  if confirm "Run Certbot now to obtain/renew certificates and auto-configure ${SERVER}?"; then
    sudo certbot "$flag"
    echo_info "Testing renewal (dry-run)..."
    sudo certbot renew --dry-run || echo_error "Renewal dry-run reported issues."
  else
    echo_note "You can run later: sudo certbot ${flag}"
  fi
}

main "$@"
