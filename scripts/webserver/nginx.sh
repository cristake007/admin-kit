#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This will install Nginx."
  echo_info "After installation, the Nginx service will be enabled and started."
  echo_info "The script will first detect if Apache is installed, as both web servers conflict (bind to ports 80/443)."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  # Abort if nginx present (port 80/443 conflict)
  if apt_is_installed apache2; then
    echo_error "Apache is installed. Apache and Nginx both bind to 80/443 — exiting."
    exit 1
  fi

  # If Apache already present, stop here (like apt would do on re-run)
  if apt_is_installed nginx; then
    echo_success "Nginx is already installed."
  else
    echo_note "Installing Nginx via APT..."
    apt_update
    apt_install nginx
    echo_success "Nginx installed."
  fi

  # Show simple status (no changes)
  echo_info "Service state: $(systemctl is-active nginx 2>/dev/null || echo inactive)"
  echo_info "Enabled at boot: $(systemctl is-enabled nginx 2>/dev/null || echo unknown)"
}

main