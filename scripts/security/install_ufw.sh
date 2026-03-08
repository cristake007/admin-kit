#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/validate.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  local ssh_port web
  echo_info "UFW basic setup (safe defaults)."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if ! command_exists ufw && [[ ! -x /usr/sbin/ufw ]]; then
    apt_update
    apt_install ufw
  fi

  while true; do
    read -r -p "SSH port [22]: " ssh_port
    ssh_port="${ssh_port:-22}"
    if validate_port "$ssh_port"; then
      break
    fi
    echo_error "Invalid port. Enter a value between 1 and 65535."
  done

  read -r -p "Allow HTTP+HTTPS (80/443)? (Y/n): " web
  web="${web:-Y}"

  echo_note "Applying UFW rules..."
  sudo /usr/sbin/ufw --force reset
  sudo /usr/sbin/ufw default deny incoming
  sudo /usr/sbin/ufw default allow outgoing
  sudo /usr/sbin/ufw allow "${ssh_port}/tcp"

  if [[ "$web" =~ ^[Yy]$ ]]; then
    sudo /usr/sbin/ufw allow 80/tcp
    sudo /usr/sbin/ufw allow 443/tcp
  fi

  sudo /usr/sbin/ufw --force enable
  echo_success "UFW configured."
  sudo /usr/sbin/ufw status verbose
}

main "$@"
