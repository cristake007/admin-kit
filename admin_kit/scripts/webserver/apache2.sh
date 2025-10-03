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
    echo_info "Cancelled."
    exit 0
  fi

  # Check if Apache2 is already installed
  if apt_is_installed apache2; then
    echo_success "Apache2 is already installed."
    
    # Enable the service
    if ! sudo systemctl enable apache2 2>/dev/null; then
      echo_error "Failed to enable Apache2 service."
      exit 1
    fi
    
    # Start the service if not running
    if ! systemctl is-active --quiet apache2; then
      echo_note "Apache2 is not running. Starting it now..."
      if ! sudo systemctl start apache2; then
        echo_error "Failed to start Apache2. Check status with: sudo systemctl status apache2"
        echo_info "Check logs with: sudo journalctl -xeu apache2"
        exit 1
      fi
    fi
    
    echo_success "Apache2 is enabled and running."
    echo_info "Status: $(systemctl is-active apache2) | Enabled: $(systemctl is-enabled apache2 2>/dev/null || echo unknown)"
    exit 0
  fi

  # Check for Nginx conflict
  if apt_is_installed nginx; then
    echo_error "Nginx is already installed. Apache2 conflicts with Nginx (both bind to ports 80/443)."
    echo_info "Stop Nginx first with: sudo systemctl stop nginx && sudo systemctl disable nginx"
    exit 1
  fi

  # Check if port 80 is already in use
  if sudo ss -tlnp 2>/dev/null | grep -q ':80 ' || sudo netstat -tlnp 2>/dev/null | grep -q ':80 '; then
    echo_error "Port 80 is already in use by another service."
    echo_info "Services using port 80:"
    sudo ss -tlnp 2>/dev/null | grep ':80 ' || sudo netstat -tlnp 2>/dev/null | grep ':80 ' || true
    exit 1
  fi

  echo_note "Updating apt metadata..."
  if ! apt_update; then
    echo_error "Failed to update apt metadata."
    exit 1
  fi

  echo_note "Installing package: apache2"
  if ! apt_install apache2; then
    echo_error "Failed to install Apache2."
    echo_info "Try running manually: sudo apt install -y apache2"
    exit 1
  fi

  # Verify installation
  if ! apt_is_installed apache2; then
    echo_error "Apache2 installation verification failed."
    exit 1
  fi

  echo_note "Enabling common Apache modules (rewrite, headers)..."
  sudo a2enmod rewrite headers 2>&1 | grep -v "^Considering" || true

  echo_note "Enabling Apache2 service..."
  if ! sudo systemctl enable apache2; then
    echo_error "Failed to enable Apache2 service."
    exit 1
  fi

  echo_note "Starting Apache2 service..."
  if ! sudo systemctl start apache2; then
    echo_error "Failed to start Apache2."
    echo_info "Check status with: sudo systemctl status apache2"
    echo_info "Check logs with: sudo journalctl -xeu apache2"
    echo_info "Check configuration with: sudo apache2ctl configtest"
    exit 1
  fi

  # Verify Apache2 is actually running
  sleep 2
  if ! systemctl is-active --quiet apache2; then
    echo_error "Apache2 failed to start or crashed immediately."
    echo_info "Check logs with: sudo journalctl -xeu apache2"
    exit 1
  fi

  # Configure firewall if UFW is available and active
  if command_exists ufw; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
      echo_note "Allowing HTTP (80/tcp) via UFW..."
      sudo ufw allow 80/tcp comment 'Apache HTTP' 2>/dev/null || true
      
      if confirm "Also open HTTPS (443/tcp) in UFW?"; then
        sudo ufw allow 443/tcp comment 'Apache HTTPS' 2>/dev/null || true
      fi
      
      sudo ufw reload 2>/dev/null || true
    else
      echo_info "UFW is installed but not active; skipping firewall rules."
    fi
  else
    echo_info "UFW not installed; skipping firewall rules."
  fi

  echo ""
  echo_success "Apache2 is installed and running."
  
  local status=$(systemctl is-active apache2 2>/dev/null || echo "unknown")
  local enabled=$(systemctl is-enabled apache2 2>/dev/null || echo "unknown")
  
  echo_info "Status: $status | Enabled: $enabled"
  echo_info "Default web root: /var/www/html"
  echo_info "Configuration: /etc/apache2/"
  
  # Try to get the server IP
  local server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [[ -n "$server_ip" ]]; then
    echo_info "Test in browser: http://$server_ip"
  fi
}

main
