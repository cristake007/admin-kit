#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This script will create a new user with sudo privileges."
  echo_info "Usernames must start with a letter and can contain lowercase letters, digits, underscores, and hyphens. Maximum length is 32 characters."
  echo ""
  
  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  while true; do
    read -r -p "Enter a username to create: " username

    # Validate: starts with letter; then lowercase letters/digits/_/-; max 32
    if [[ "$username" =~ ^[a-z][-a-z0-9_]{0,31}$ ]]; then
      if id "$username" &>/dev/null; then
        echo_info "User '$username' already exists."
      else
        echo_note "Creating user '$username'..."
        script -qec "sudo adduser \"$username\"" /dev/null
        echo_note "Adding '$username' to 'sudo' group..."
        sudo usermod -aG sudo "$username"
        echo_success "User '$username' created and added to sudo group."
      fi
      break
    else
      echo_error "Invalid username. Use lowercase letters, digits, underscores; max 32 chars; start with a letter."
    fi
  done
}

main
