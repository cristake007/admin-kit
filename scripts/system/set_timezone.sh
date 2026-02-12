#!/usr/bin/env bash
# Metadata:
# Requires: timedatectl (preferred) OR tzdata package
# Privileges: root or sudo
# Target distro: Debian/Ubuntu (systemd-friendly)
# Side effects: updates system timezone (timedatectl or /etc/timezone)
# Safe to re-run: yes
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"
trap 'err_trap' ERR

need_sudo || exit 1

timezone_exists() {
  local tz="$1"
  if command_exists timedatectl; then
    timedatectl list-timezones | grep -Fxq "$tz"
  else
    [[ -f "/usr/share/zoneinfo/$tz" ]]
  fi
}

current_timezone() {
  if command_exists timedatectl; then
    timedatectl show -p Timezone --value 2>/dev/null || true
  elif [[ -f /etc/timezone ]]; then
    cat /etc/timezone
  fi
}

main() {
  local current_tz
  current_tz="$(current_timezone)"

  echo_info "Set the system timezone."
  show_script_metadata \
    "timedatectl or tzdata" \
    "root or sudo" \
    "Debian/Ubuntu" \
    "modifies timezone configuration" \
    "yes"

  if [[ -n "$current_tz" ]]; then
    echo_note "Current timezone: $current_tz"
  fi

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."
    exit 0
  fi

  read -r -p "Enter timezone [Europe/Bucharest]: " TZ_INPUT
  TZ_INPUT="${TZ_INPUT:-Europe/Bucharest}"

  if ! timezone_exists "$TZ_INPUT"; then
    echo_error "Invalid timezone: $TZ_INPUT"
    echo_info "Example format: Region/City (e.g., Europe/Bucharest)"
    exit 1
  fi

  echo_note "Setting timezone to ${TZ_INPUT}..."
  if command_exists timedatectl; then
    run_privileged timedatectl set-timezone "$TZ_INPUT"
  else
    apt_update
    apt_install tzdata
    run_privileged sh -c "printf '%s\n' '$TZ_INPUT' > /etc/timezone"
    run_privileged dpkg-reconfigure -f noninteractive tzdata
  fi

  echo_success "Timezone set to ${TZ_INPUT}."
}

main "$@"
