#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"
trap 'err_trap' ERR

need_sudo || exit 1

main() {
  echo_info "UFW basic setup (safe defaults)"
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  # Ensure ufw exists
  if ! sudo command -v ufw >/dev/null 2>&1 && [[ ! -x /usr/sbin/ufw ]]; then
    echo_note "Installing ufw..."
    apt_update
    apt_install ufw
  fi

  # Use explicit binary path to avoid PATH issues in non-interactive shells
  local UFW="/usr/sbin/ufw"
  [[ -x "$UFW" ]] || UFW="$(command -v ufw)"

  local SSH_PORT WEB
  read -r -p "SSH port [22]: " SSH_PORT
  SSH_PORT="${SSH_PORT:-22}"

  read -r -p "Allow HTTP+HTTPS (80/443)? (Y/n): " WEB
  WEB="${WEB:-Y}"

  echo_note "Applying UFW rules..."
  sudo "$UFW" --force reset
  sudo "$UFW" default deny incoming
  sudo "$UFW" default allow outgoing
  sudo "$UFW" allow "${SSH_PORT}/tcp"

  if [[ "$WEB" == "y" || "$WEB" == "Y" ]]; then
    sudo "$UFW" allow 80/tcp
    sudo "$UFW" allow 443/tcp
  fi

  sudo "$UFW" --force enable

  echo_success "UFW configured."
  sudo "$UFW" status verbose
}

main "$@"
