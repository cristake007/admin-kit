#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"
trap 'err_trap' ERR

need_sudo || exit 1

main() {
  echo_info "Set system hostname"
  echo_note "Type 'q' anytime to cancel."
  echo

  local current_hn current_fqdn
  current_hn="$(hostname)"
  current_fqdn="$(hostname -f 2>/dev/null || echo 'N/A')"
  echo_note "Current hostname: ${current_hn}"
  echo_note "Current FQDN: ${current_fqdn}"
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  local HN DN FQDN
  while :; do
    read -r -p "Enter short hostname (e.g., app01): " HN || { echo_info "Cancelled."; exit 0; }
    HN="${HN,,}"          # lowercase
    HN="${HN// /}"        # remove spaces

    [[ "$HN" == "q" ]] && { echo_info "Cancelled."; exit 0; }

    # 1-63 chars, a-z0-9-, cannot start/end with -
    if [[ "$HN" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
      break
    fi
    echo_error "Invalid hostname. Use letters/digits/hyphens, no leading/trailing hyphen."
  done

  while :; do
    read -r -p "Enter domain (optional, e.g., example.com): " DN || { echo_info "Cancelled."; exit 0; }
    DN="${DN,,}"
    DN="${DN// /}"

    [[ "$DN" == "q" ]] && { echo_info "Cancelled."; exit 0; }

    # empty is allowed
    if [[ -z "$DN" ]]; then
      break
    fi

    # simple domain validation (labels separated by dots, no leading/trailing hyphens)
    if [[ "$DN" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]; then
      break
    fi
    echo_error "Invalid domain format. Example: example.com"
  done

  FQDN="$HN"
  [[ -n "$DN" ]] && FQDN="${HN}.${DN}"

  echo_note "Setting hostname to ${FQDN}..."
  sudo hostnamectl set-hostname "$FQDN"

  # update /etc/hosts safely (with sudo)
  if grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]+' /etc/hosts; then
    sudo sed -i -E "s|^[[:space:]]*127\.0\.1\.1[[:space:]].*$|127.0.1.1\t${FQDN} ${HN}|g" /etc/hosts
  else
    printf "127.0.1.1\t%s %s\n" "$FQDN" "$HN" | sudo tee -a /etc/hosts >/dev/null
  fi

  echo_success "Hostname configured: ${FQDN}"
}
main "$@"
