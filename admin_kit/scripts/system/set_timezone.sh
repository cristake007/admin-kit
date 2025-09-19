#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This script will set the system's timezone."
  echo_info "You can specify a timezone in the format 'Region/City', e.g., 'Europe/Bucharest'."
  echo_info "If you leave it blank, the default 'Europe/Bucharest' will be used."
  echo ""

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  read -r -p "Enter timezone [Europe/Bucharest]: " TZ_INPUT
  TZ_INPUT="${TZ_INPUT:-Europe/Bucharest}"

  echo_note "Setting timezone to ${TZ_INPUT}..."
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone "${TZ_INPUT}"
  else
    apt_update
    apt_install tzdata
    echo "${TZ_INPUT}" >/etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
  fi

  echo_success "Timezone set to ${TZ_INPUT}."
}

main