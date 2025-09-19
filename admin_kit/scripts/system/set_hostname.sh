#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This script will set the system's hostname."
  echo_info "You can set a short hostname and an optional domain to form a fully qualified domain name (FQDN)."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  read -r -p "Enter short hostname (e.g., app01): " HN
  if [[ -z "${HN:-}" ]]; then
    echo_error "Hostname cannot be empty."
    exit 1
  fi
  read -r -p "Enter domain (optional, e.g., example.com): " DN
  FQDN="$HN"
  [[ -n "${DN:-}" ]] && FQDN="${HN}.${DN}"

  echo_note "Setting hostname to ${FQDN}..."
  hostnamectl set-hostname "${FQDN}"

  # Ensure Debian-style 127.0.1.1 mapping
  if grep -qE '^\s*127\.0\.1\.1\s' /etc/hosts; then
    sed -i -E "s|^\s*127\.0\.1\.1\s.*$|127.0.1.1\t${FQDN} ${HN}|g" /etc/hosts
  else
    printf "127.0.1.1\t%s %s\n" "${FQDN}" "${HN}" >> /etc/hosts
  fi

  echo_success "Hostname configured: ${FQDN}"
}

main