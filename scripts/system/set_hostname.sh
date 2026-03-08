#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Set system hostname and keep /etc/hosts in sync.
# Supports: linux with hostnamectl
# Requires: root privileges
# Safe to rerun: yes
# Side effects: hostname and /etc/hosts changes

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib validate
require_lib file

main() {
  need_root

  local short_name="${1:-}"
  local domain_name="${2:-}"
  if [[ -z "$short_name" ]]; then
    read -r -p "Enter short hostname: " short_name
  fi
  if [[ -z "$domain_name" ]]; then
    read -r -p "Enter domain (optional): " domain_name
  fi

  if ! validate_hostname "$short_name"; then
    error "Invalid hostname: $short_name"
    return 1
  fi
  if ! validate_domain "$domain_name"; then
    error "Invalid domain: $domain_name"
    return 1
  fi

  local fqdn="$short_name"
  if [[ -n "$domain_name" ]]; then
    fqdn="$short_name.$domain_name"
  fi

  hostnamectl set-hostname "$fqdn"
  backup_file /etc/hosts
  replace_or_add_key_value /etc/hosts "127.0.1.1" "$fqdn $short_name"
  success "Hostname configured to $fqdn"
}

main "$@"
