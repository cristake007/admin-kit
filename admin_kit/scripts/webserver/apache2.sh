#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This will install Apache2."
  echo_info "After installation, the Apache2 service will be enabled and started."
  echo_info "The script will first detect if Nginx is installed, as both web servers conflict (bind to ports 80/443)."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if apt_is_installed apache2; then
    echo_success "Apache2 is already installed."
    sudo systemctl enable --now apache2
    exit 0
  fi

  if apt_is_installed nginx; then
    echo_error "Nginx is already installed. Apache2 conflicts with Nginx (both bind to ports 80/443)."
    exit 1
  fi

  echo_note "Updating apt metadata..."
  apt_update

  echo_note "Installing package: apache2"
  apt_install apache2

  echo_note "Enabling common Apache modules (rewrite, headers)..."
  sudo a2enmod rewrite headers >/dev/null || true

  echo_note "Enabling & starting Apache2 service..."
  sudo systemctl enable --now apache2

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

  echo_success "Apache2 is installed and running."
  echo_info "Status: $(systemctl is-active apache2) | Enabled: $(systemctl is-enabled apache2 2>/dev/null || echo unknown)"
}

main