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
  local current_hn current_fqdn hn dn fqdn
  echo_info "Set system hostname"
  echo_note "Type 'q' anytime to cancel."
  echo

  current_hn="$(hostname)"
  current_fqdn="$(hostname -f 2>/dev/null || echo 'N/A')"
  echo_note "Current hostname: ${current_hn}"
  echo_note "Current FQDN: ${current_fqdn}"
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  while true; do
    read -r -p "Enter short hostname (e.g., app01): " hn
    hn="${hn,,}"
    hn="${hn// /}"
    [[ "$hn" == "q" ]] && { echo_info "Cancelled."; exit 0; }
    validate_hostname_label "$hn" && break
    echo_error "Invalid hostname. Use letters/digits/hyphens, no leading/trailing hyphen. Example: app01"
  done

  while true; do
    read -r -p "Enter domain (optional, e.g., example.com): " dn
    dn="${dn,,}"
    dn="${dn// /}"
    [[ "$dn" == "q" ]] && { echo_info "Cancelled."; exit 0; }
    validate_domain "$dn" && break
    echo_error "Invalid domain format. Example: example.com"
  done

  fqdn="$hn"
  [[ -n "$dn" ]] && fqdn="${hn}.${dn}"

  echo_note "Setting hostname to ${fqdn}..."
  sudo hostnamectl set-hostname "$fqdn"

  if grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]+' /etc/hosts; then
    sudo sed -i -E "s|^[[:space:]]*127\.0\.1\.1[[:space:]].*$|127.0.1.1\t${fqdn} ${hn}|g" /etc/hosts
  else
    printf "127.0.1.1\t%s %s\n" "$fqdn" "$hn" | sudo tee -a /etc/hosts >/dev/null
  fi

  echo_success "Hostname configured: ${fqdn}"
}

main "$@"
