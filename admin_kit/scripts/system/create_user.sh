#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This script will create a new user with sudo privileges."
  echo_info "Usernames must start with a letter and can contain lowercase letters, digits, underscores, and hyphens."
  echo_info "Maximum length is 32 characters."
  echo ""
  
  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."
    exit 0
  fi

  local username
  while true; do
    read -r -p "Enter a username to create: " username
    
    # Trim whitespace
    username=$(echo "$username" | xargs)
    
    # Check if empty
    if [[ -z "$username" ]]; then
      echo_error "Username cannot be empty."
      continue
    fi
    
    # Validate: starts with letter; then lowercase letters/digits/_/-; max 32
    if [[ ! "$username" =~ ^[a-z][-a-z0-9_]{0,31}$ ]]; then
      echo_error "Invalid username format."
      echo_info "Rules: Start with lowercase letter, then use lowercase letters, digits, underscores, or hyphens. Max 32 characters."
      continue
    fi
    
    # Check if user already exists
    if user_exists "$username"; then
      echo_error "User '$username' already exists."
      if ! confirm "Try a different username?"; then
        echo_info "Cancelled."
        exit 0
      fi
      continue
    fi
    
    # Username is valid and doesn't exist, proceed
    break
  done

  echo ""
  echo_note "Creating user '$username'..."
  
  # Use adduser (Debian/Ubuntu) which is more interactive and user-friendly
  # The script command ensures password prompts work correctly
  if ! script -qec "sudo adduser \"$username\"" /dev/null; then
    echo_error "Failed to create user '$username'."
    echo_info "You can try manually with: sudo adduser $username"
    exit 1
  fi
  
  # Verify user was created
  if ! user_exists "$username"; then
    echo_error "User creation appeared to succeed but user doesn't exist."
    exit 1
  fi
  
  echo_note "Adding '$username' to 'sudo' group..."
  if ! sudo usermod -aG sudo "$username"; then
    echo_error "Failed to add user '$username' to sudo group."
    echo_info "You can try manually with: sudo usermod -aG sudo $username"
    exit 1
  fi
  
  # Verify user is in sudo group
  if id -nG "$username" 2>/dev/null | grep -qw sudo; then
    echo_success "User '$username' created and added to sudo group."
  else
    echo_error "User created but failed to verify sudo group membership."
    exit 1
  fi
  
  echo ""
  echo_info "User details:"
  echo_info "  Username: $username"
  echo_info "  Home: $(getent passwd "$username" | cut -d: -f6)"
  echo_info "  Shell: $(getent passwd "$username" | cut -d: -f7)"
  echo_info "  Groups: $(id -nG "$username" | tr ' ' ',')"
  
  echo ""
  if confirm "Do you want to configure SSH key authentication for this user?"; then
    configure_ssh_key "$username"
  fi
  
  echo ""
  echo_success "Setup complete!"
  echo_note "The user can now log in and use sudo with their password."
  echo_note "To switch to this user: su - $username"
  echo_note "To test sudo access: sudo -u $username sudo -v"
}

configure_ssh_key() {
  local username="$1"
  local home_dir
  home_dir=$(getent passwd "$username" | cut -d: -f6)
  
  if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
    echo_error "Home directory not found for user '$username'."
    return 1
  fi
  
  local ssh_dir="$home_dir/.ssh"
  local authorized_keys="$ssh_dir/authorized_keys"
  
  echo ""
  echo_info "SSH Key Configuration"
  echo_info "You can either:"
  echo_info "  1) Paste an existing public key"
  echo_info "  2) Generate a new SSH key pair"
  echo ""
  
  read -r -p "Choose option [1/2]: " ssh_option
  
  case "$ssh_option" in
    1)
      echo_info "Paste the public key (starts with 'ssh-rsa', 'ssh-ed25519', etc.):"
      read -r pubkey
      
      # Basic validation
      if [[ ! "$pubkey" =~ ^ssh- ]]; then
        echo_error "Invalid public key format. Must start with 'ssh-'"
        return 1
      fi
      
      # Create .ssh directory
      sudo mkdir -p "$ssh_dir"
      
      # Add key
      echo "$pubkey" | sudo tee -a "$authorized_keys" >/dev/null
      
      # Set permissions
      sudo chmod 700 "$ssh_dir"
      sudo chmod 600 "$authorized_keys"
      sudo chown -R "$username:$username" "$ssh_dir"
      
      echo_success "SSH key added to $authorized_keys"
      ;;
      
    2)
      echo_note "Generating new SSH key pair for '$username'..."
      
      # Create .ssh directory if it doesn't exist
      sudo -u "$username" mkdir -p "$ssh_dir"
      sudo -u "$username" chmod 700 "$ssh_dir"
      
      local key_path="$ssh_dir/id_ed25519"
      
      # Generate key as the user
      if sudo -u "$username" ssh-keygen -t ed25519 -f "$key_path" -N "" -C "$username@$(hostname)"; then
        echo_success "SSH key pair generated:"
        echo_info "  Private key: $key_path"
        echo_info "  Public key: $key_path.pub"
        echo ""
        echo_note "Public key content:"
        sudo cat "$key_path.pub"
        echo ""
        echo_info "Save the private key securely and use it to connect to this server."
        
        # Also add to authorized_keys for convenience
        sudo cat "$key_path.pub" | sudo tee "$authorized_keys" >/dev/null
        sudo chmod 600 "$authorized_keys"
        sudo chown "$username:$username" "$authorized_keys"
        echo_success "Public key also added to authorized_keys."
      else
        echo_error "Failed to generate SSH key."
        return 1
      fi
      ;;
      
    *)
      echo_info "Skipping SSH key configuration."
      ;;
  esac
  
  return 0
}

main
