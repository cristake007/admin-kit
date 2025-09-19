#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

install_nginx() {
  echo_info "This will install Nginx."
  echo_info "After installation, the Nginx service will be enabled and started."
  echo_info "The script will first detect if Apache2 is installed, as both web servers conflict (bind to ports 80/443)."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if apt_is_installed nginx; then
    echo_success "Nginx is already installed."
    sudo systemctl enable --now nginx
    exit 0
  fi

  if apt_is_installed apache2; then
    echo_error "Apache2 is already installed. Nginx conflicts with Apache2 (both bind to ports 80/443)."
    exit 1
  fi

  if ! confirm "Proceed with Nginx installation?"; then
    echo_info "Cancelled."; exit 0
  fi

  echo_note "Updating apt metadata..."
  apt_update

  echo_note "Installing package: nginx"
  apt_install nginx

  echo_note "Enabling & starting Nginx service..."
  sudo systemctl enable --now nginx

  if command -v ufw >/dev/null 2>&1; then
    echo_note "Allowing HTTP (80/tcp) via UFW..."
    sudo ufw allow 80/tcp || true
    if confirm "Also open HTTPS (443/tcp) in UFW?"; then
      sudo ufw allow 443/tcp || true
    fi
    sudo ufw reload || true
  else
    echo_info "UFW not installed; skipping firewall rules."
  fi

  echo_success "Nginx is installed and running."
  echo_info "Status: $(systemctl is-active nginx) | Enabled: $(systemctl is-enabled nginx 2>/dev/null || echo unknown)"
}

install_nginx