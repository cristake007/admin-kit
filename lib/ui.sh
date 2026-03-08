#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_UI_SH:-}" ]] && return 0
__LIB_UI_SH=1

pause() {
  read -r -p "Press Enter to continue..." _unused
}

confirm() {
  local prompt="${1:-Proceed?}"
  local answer
  read -r -p "$prompt (y/N): " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

display_header() {
  local title="${1:-ADMIN KIT}"
  printf '\n=== %s ===\n' "$title"
  printf 'Host: %s | Kernel: %s\n\n' "$(hostname)" "$(uname -r)"
}
