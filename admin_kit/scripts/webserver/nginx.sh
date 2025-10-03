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
    echo_info "Cancelled."
    exit 0
  fi

  # Check if Nginx is already installed
  if apt_is_installed nginx; then
    echo_success "Nginx is already installed."
    
    # Enable the service
    if ! sudo systemctl enable nginx 2>/dev/null; then
      echo_error "Failed to enable Nginx service."
      exit 1
    fi
    
    # Start the service if not running
    if ! systemctl is-active --quiet nginx; then
      echo_note "Nginx is not running. Starting it now..."
      if ! sudo systemctl start nginx; then
        echo_error "Failed to start Nginx. Check status with: sudo systemctl status nginx"
        echo_info "Check logs with: sudo journalctl -xeu nginx"
        exit 1
      fi
    fi
    
    echo_success "Nginx is enabled and running."
    echo_info "Status: $(systemctl is-active nginx) | Enabled: $(systemctl is-enabled nginx 2>/dev/null || echo unknown)"
    exit 0
  fi

  # Check for Apache2 conflict
  if apt_is_installed apache2; then
    echo_error "Apache2 is already installed. Nginx conflicts with Apache2 (both bind to ports 80/443)."
    echo_info "Stop Apache2 first with: sudo systemctl stop apache2 && sudo systemctl disable apache2"
    exit 1
  fi

  # Check if port 80 is already in use
  if sudo ss -tlnp 2>/dev/null | grep -q ':80 ' || sudo netstat -tlnp 2>/dev/null | grep -q ':80 '; then
    echo_error "Port 80 is already in use by another service."
    echo_info "Services using port 80:"
    sudo ss -tlnp 2>/dev/null | grep ':80 ' || sudo netstat -tlnp 2>/dev/null | grep ':80 ' || true
    exit 1
  fi

  if ! confirm "Proceed with Nginx installation?"; then
    echo_info "Cancelled."
    exit 0
  fi

  echo_note "Updating apt metadata..."
  if ! apt_update; then
    echo_error "Failed to update apt metadata."
    exit 1
  fi

  echo_note "Installing package: nginx"
  if ! apt_install nginx; then
    echo_error "Failed to install Nginx."
    echo_info "Try running manually: sudo apt install -y nginx"
    exit 1
  fi

  # Verify installation
  if ! apt_is_installed nginx; then
    echo_error "Nginx installation verification failed."
    exit 1
  fi

  echo_note "Enabling Nginx service..."
  if ! sudo systemctl enable nginx; then
    echo_error "Failed to enable Nginx service."
    exit 1
  fi

  echo_note "Starting Nginx service..."
  if ! sudo systemctl start nginx; then
    echo_error "Failed to start Nginx."
    echo_info "Check status with: sudo systemctl status nginx"
    echo_info "Check logs with: sudo journalctl -xeu nginx"
    echo_info "Check configuration with: sudo nginx -t"
    exit 1
  fi

  # Verify Nginx is actually running
  sleep 2
  if ! systemctl is-active --quiet nginx; then
    echo_error "Nginx failed to start or crashed immediately."
    echo_info "Check logs with: sudo journalctl -xeu nginx"
    exit 1
  fi

  # Configure firewall if UFW is available and active
  if command_exists ufw; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
      echo_note "Allowing HTTP (80/tcp) via UFW..."
      sudo ufw allow 80/tcp comment 'Nginx HTTP' 2>/dev/null || true
      
      if confirm "Also open HTTPS (443/tcp) in UFW?"; then
        sudo ufw allow 443/tcp comment 'Nginx HTTPS' 2>/dev/null || true
      fi
      
      sudo ufw reload 2>/dev/null || true
    else
      echo_info "UFW is installed but not active; skipping firewall rules."
    fi
  else
    echo_info "UFW not installed; skipping firewall rules."
  fi

  echo ""
  echo_success "Nginx is installed and running."
  
  local status=$(systemctl is-active nginx 2>/dev/null || echo "unknown")
  local enabled=$(systemctl is-enabled nginx 2>/dev/null || echo "unknown")
  
  echo_info "Status: $status | Enabled: $enabled"
  echo_info "Default web root: /var/www/html"
  echo_info "Configuration: /etc/nginx/"
  
  # Try to get the server IP
  local server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [[ -n "$server_ip" ]]; then
    echo_info "Test in browser: http://$server_ip"
  fi
}

install_nginx
