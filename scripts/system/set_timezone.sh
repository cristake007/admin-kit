#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Configure timezone.
# Supports: linux with timedatectl
# Requires: root privileges
# Safe to rerun: yes
# Side effects: timezone configuration

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core

main() {
  need_root
  local tz="${1:-Europe/Bucharest}"

  if ! timedatectl list-timezones | grep -Fxq "$tz"; then
    error "Unknown timezone: $tz"
    return 1
  fi

  timedatectl set-timezone "$tz"
  success "Timezone set to $tz"
}

main "$@"
