#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/service.sh"
require "lib/validate.sh"
require "lib/security.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  echo_info "This installs Certbot for Apache or Nginx."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  detect_server || exit 1
  echo_info "Using web server: ${SERVER}"

  if apt_package_installed certbot; then
    echo_info "Certbot is already installed."
  else
    apt_update
    apt_install certbot
  fi

  if [[ "$SERVER" == "apache" ]]; then
    apt_package_installed python3-certbot-apache || apt_install python3-certbot-apache
    service_enable_now apache2 || true
    service_status_line apache2
  else
    apt_package_installed python3-certbot-nginx || apt_install python3-certbot-nginx
    service_enable_now nginx || true
    service_status_line nginx
  fi

  configure_firewall
  maybe_run_certbot_now
  echo_success "Certbot setup for ${SERVER} completed."
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
