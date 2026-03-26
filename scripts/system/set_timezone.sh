#!/usr/bin/env bash
set -Eeuo pipefail
# NON-INSTALLER: utility/orchestration script; not part of installer workflow contract.

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
  local tz_input
  echo_info "This script sets the system timezone."
  echo_info "Format: Region/City (example: Europe/Bucharest)."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  while true; do
    read -r -p "Enter timezone [Europe/Bucharest]: " tz_input
    tz_input="${tz_input:-Europe/Bucharest}"
    if validate_timezone "$tz_input"; then
      break
    fi
    echo_error "Invalid timezone. Example: Europe/Bucharest"
  done

  echo_note "Setting timezone to ${tz_input}..."
  if command_exists timedatectl; then
    sudo timedatectl set-timezone "$tz_input"
  else
    apt_update
    apt_install tzdata
    echo "$tz_input" | sudo tee /etc/timezone >/dev/null
    sudo dpkg-reconfigure -f noninteractive tzdata
  fi

  echo_success "Timezone set to ${tz_input}."
}

main "$@"
