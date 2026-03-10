#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/validate.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  local username
  echo_info "This script will create a new user with sudo privileges."
  echo_info "Allowed format: starts with a letter; then lowercase letters, digits, '_' or '-'; max 32 chars."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  while true; do
    read -r -p "Enter a username to create: " username
    if ! validate_username "$username"; then
      echo_error "Invalid username. Example: admin01"
      continue
    fi

  if user_exists "$username"; then
    echo_info "User '$username' already exists."
    confirm "Add '$username' to sudo group anyway?" && {
      sudo usermod -aG sudo "$username"
      echo_success "User '$username' added to sudo group."
    }
    break
  fi

    echo_note "Creating user '$username'..."
    sudo adduser "$username"
    echo_note "Adding '$username' to 'sudo' group..."
    sudo usermod -aG sudo "$username"
    echo_success "User '$username' created and added to sudo group."
    break
  done
}

main "$@"
