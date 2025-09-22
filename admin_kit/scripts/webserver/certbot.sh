#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This script will install and configure Certbot for obtaining and renewing SSL certificates."
  echo_info "It supports both Apache and Nginx web servers."
  echo_info "Make sure you have either Apache or Nginx installed before running this script."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if ! detect_server; then
    # detect_server already prints a helpful message
    exit 1
  fi
  echo_info "Using web server: ${SERVER}"

  install_certbot_for_server
  configure_firewall
  ensure_server_running
  maybe_run_certbot_now

  echo_success "Certbot setup for ${SERVER} completed."
}

# Decide which server to use (sets global $SERVER to 'apache' or 'nginx')
detect_server() {
  local has_apache=1 has_nginx=1
  if apt_is_installed apache2 || systemctl is-active --quiet apache2 2>/dev/null; then has_apache=0; fi
  if apt_is_installed nginx   || systemctl is-active --quiet nginx   2>/dev/null; then has_nginx=0; fi

  if (( has_apache != 0 && has_nginx != 0 )); then
    echo_error "No supported webserver detected."
    echo_info  "Please install Apache or Nginx first."
    return 1
  fi

  if (( has_apache == 0 && has_nginx == 0 )); then
    echo_info "Both Apache and Nginx detected."
    while true; do
      echo -ne "${YELLOW}Use Certbot with which server? [a) Apache / n) Nginx]: ${NC}"
      read -r sel
      case "$sel" in
        a|A) SERVER="apache"; break ;;
        n|N) SERVER="nginx";  break ;;
        *)   echo_error "Please choose 'a' or 'n'." ;;
      esac
    done
  elif (( has_apache == 0 )); then
    SERVER="apache"
  else
    SERVER="nginx"
  fi
  return 0
}

# Small helper for DRY-ness
certbot_plugin_flag() {
  case "${SERVER:?SERVER not set}" in
    apache) echo "--apache" ;;
    nginx)  echo "--nginx"  ;;
    *) echo_error "Unknown SERVER: ${SERVER}"; return 1 ;;
  esac
}

install_certbot_for_server() {
  echo_note "Installing Certbot for ${SERVER:?SERVER not set}..."
  apt_update
  apt_install certbot
  if [[ "$SERVER" == "apache" ]]; then
    apt_install python3-certbot-apache
  else
    apt_install python3-certbot-nginx
  fi
  echo_success "Certbot installed for ${SERVER}."
}

configure_firewall() {
  if command -v ufw >/dev/null 2>&1; then
    echo_note "Ensuring UFW allows HTTP/HTTPS..."
    ufw allow 80/tcp || true
    ufw allow 443/tcp || true
    ufw reload || true
  else
    echo_info "UFW not installed; skipping firewall rules."
  fi
}

ensure_server_running() {
  echo_note "Ensuring ${SERVER} service is enabled and running..."
  if [[ "${SERVER:?}" == "apache" ]]; then
    systemctl enable --now apache2 || true
  else
    systemctl enable --now nginx || true
  fi
}

maybe_run_certbot_now() {
  local flag
  flag="$(certbot_plugin_flag)"

  if confirm "Run Certbot now to obtain/renew certificates and auto-configure ${SERVER}?"; then
    certbot "${flag}"
    echo_info "Testing renewal (dry-run)..."
    certbot renew --dry-run || echo_error "Renewal dry-run reported issues."
  else
    echo_info "Skipping interactive Certbot run."
    echo_note "You can run later: sudo certbot ${flag}"
  fi
}

main
