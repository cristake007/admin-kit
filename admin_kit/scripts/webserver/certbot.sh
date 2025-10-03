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
    echo_info "Cancelled."
    exit 0
  fi

  if ! detect_server; then
    # detect_server already prints a helpful message
    exit 1
  fi

  echo_info "Using web server: ${SERVER}"
  
  if ! install_certbot_for_server; then
    echo_error "Failed to install Certbot for ${SERVER}."
    exit 1
  fi
  
  configure_firewall
  
  if ! ensure_server_running; then
    echo_error "Failed to start ${SERVER} service."
    exit 1
  fi
  
  maybe_run_certbot_now
  
  echo ""
  echo_success "Certbot setup for ${SERVER} completed."
  echo_info "Certbot will automatically renew certificates via systemd timer."
  echo_info "Check timer status with: sudo systemctl status certbot.timer"
}

# Decide which server to use (sets global $SERVER to 'apache' or 'nginx')
detect_server() {
  local has_apache=1 has_nginx=1
  
  # Check if Apache is installed AND can start (not just installed)
  if apt_is_installed apache2; then
    has_apache=0
  fi
  
  # Check if Nginx is installed
  if apt_is_installed nginx; then
    has_nginx=0
  fi

  # Neither server found
  if (( has_apache != 0 && has_nginx != 0 )); then
    echo_error "No supported webserver detected."
    echo_info "Please install Apache or Nginx first."
    return 1
  fi

  # Both servers found
  if (( has_apache == 0 && has_nginx == 0 )); then
    echo_info "Both Apache and Nginx detected."
    
    # Check which one is actually running
    local apache_running=false nginx_running=false
    if systemctl is-active --quiet apache2 2>/dev/null; then
      apache_running=true
    fi
    if systemctl is-active --quiet nginx 2>/dev/null; then
      nginx_running=true
    fi
    
    if $apache_running && ! $nginx_running; then
      echo_info "Apache is running, Nginx is not. Defaulting to Apache."
      if confirm "Use Apache for Certbot?"; then
        SERVER="apache"
        return 0
      fi
    elif $nginx_running && ! $apache_running; then
      echo_info "Nginx is running, Apache is not. Defaulting to Nginx."
      if confirm "Use Nginx for Certbot?"; then
        SERVER="nginx"
        return 0
      fi
    fi
    
    # Let user choose
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
  
  # Update package lists
  if ! apt_update; then
    echo_error "Failed to update apt metadata."
    return 1
  fi
  
  # Install core certbot
  if ! apt_install certbot; then
    echo_error "Failed to install certbot package."
    return 1
  fi
  
  # Install plugin for specific server
  if [[ "$SERVER" == "apache" ]]; then
    if ! apt_install python3-certbot-apache; then
      echo_error "Failed to install python3-certbot-apache."
      return 1
    fi
  else
    if ! apt_install python3-certbot-nginx; then
      echo_error "Failed to install python3-certbot-nginx."
      return 1
    fi
  fi
  
  # Verify certbot command is available
  if ! command_exists certbot; then
    echo_error "Certbot command not found after installation."
    return 1
  fi
  
  # Check certbot version
  local certbot_version
  certbot_version=$(certbot --version 2>&1 | head -n1)
  echo_success "Certbot installed for ${SERVER}. Version: ${certbot_version}"
  
  # Enable and check certbot timer
  if systemctl list-unit-files certbot.timer >/dev/null 2>&1; then
    echo_note "Enabling automatic certificate renewal via systemd timer..."
    sudo systemctl enable certbot.timer 2>/dev/null || true
    sudo systemctl start certbot.timer 2>/dev/null || true
    
    if systemctl is-active --quiet certbot.timer; then
      echo_success "Certbot renewal timer is active."
    else
      echo_info "Certbot renewal timer could not be started (this may be normal)."
    fi
  fi
  
  return 0
}

configure_firewall() {
  if command_exists ufw; then
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
      echo_note "Ensuring UFW allows HTTP/HTTPS..."
      sudo ufw allow 80/tcp comment 'HTTP for Certbot' 2>/dev/null || true
      sudo ufw allow 443/tcp comment 'HTTPS for SSL' 2>/dev/null || true
      sudo ufw reload 2>/dev/null || true
      echo_success "Firewall rules configured."
    else
      echo_info "UFW is installed but not active; skipping firewall rules."
    fi
  else
    echo_info "UFW not installed; skipping firewall rules."
  fi
}

ensure_server_running() {
  echo_note "Ensuring ${SERVER} service is enabled and running..."
  
  local service_name
  if [[ "${SERVER:?}" == "apache" ]]; then
    service_name="apache2"
  else
    service_name="nginx"
  fi
  
  # Enable service
  if ! sudo systemctl enable "$service_name" 2>/dev/null; then
    echo_error "Failed to enable ${service_name} service."
    return 1
  fi
  
  # Check if already running
  if systemctl is-active --quiet "$service_name"; then
    echo_success "${SERVER} is already running."
    return 0
  fi
  
  # Try to start
  echo_note "Starting ${service_name} service..."
  if ! sudo systemctl start "$service_name"; then
    echo_error "Failed to start ${service_name}."
    echo_info "Check status with: sudo systemctl status ${service_name}"
    echo_info "Check configuration with: sudo ${service_name%2} -t"
    return 1
  fi
  
  # Verify it started
  sleep 2
  if ! systemctl is-active --quiet "$service_name"; then
    echo_error "${SERVER} failed to start or crashed immediately."
    echo_info "Check logs with: sudo journalctl -xeu ${service_name}"
    return 1
  fi
  
  echo_success "${SERVER} is enabled and running."
  return 0
}

maybe_run_certbot_now() {
  local flag
  flag="$(certbot_plugin_flag)"
  
  echo ""
  echo_info "Certbot is now installed and ready to use."
  echo_note "Before running Certbot, ensure:"
  echo_note "  1. Your domain's DNS A/AAAA records point to this server's IP"
  echo_note "  2. Port 80 (HTTP) is accessible from the internet"
  echo_note "  3. Your ${SERVER} is configured with a server block/virtual host for your domain"
  echo ""
  
  if confirm "Run Certbot now to obtain/renew certificates and auto-configure ${SERVER}?"; then
    echo_note "Running: sudo certbot ${flag}"
    echo_info "Follow the interactive prompts..."
    echo ""
    
    if sudo certbot "${flag}"; then
      echo_success "Certbot configuration completed."
      echo ""
      echo_info "Testing renewal (dry-run)..."
      if sudo certbot renew --dry-run; then
        echo_success "Renewal test passed. Auto-renewal is configured."
      else
        echo_error "Renewal dry-run reported issues. Check configuration."
      fi
    else
      echo_error "Certbot configuration failed."
      echo_info "Common issues:"
      echo_info "  - Domain DNS not pointing to this server"
      echo_info "  - Port 80 blocked by firewall"
      echo_info "  - Web server configuration issues"
      echo_info "You can try again later with: sudo certbot ${flag}"
    fi
  else
    echo_info "Skipping interactive Certbot run."
    echo_note "To obtain certificates later, run: sudo certbot ${flag}"
    echo_note "To list certificates, run: sudo certbot certificates"
    echo_note "To renew certificates, run: sudo certbot renew"
  fi
}

main
