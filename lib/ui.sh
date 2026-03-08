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

_header_line() {
  local width="${1:-0}"
  if [[ "$width" -ge 10 ]]; then
    printf '%*s\n' "$width" '' | tr ' ' '='
  else
    printf '====================\n'
  fi
}

display_header() {
  local title="${1:-ADMIN KIT}"

  local host="unknown"
  if command -v hostname >/dev/null 2>&1; then
    host="$(hostname 2>/dev/null || true)"
    host="${host:-unknown}"
  fi

  local kernel="unknown"
  if command -v uname >/dev/null 2>&1; then
    kernel="$(uname -r 2>/dev/null || true)"
    kernel="${kernel:-unknown}"
  fi

  local term_width=0
  if command -v tput >/dev/null 2>&1; then
    term_width="$(tput cols 2>/dev/null || echo 0)"
  fi
  if ! [[ "$term_width" =~ ^[0-9]+$ ]]; then
    term_width=0
  fi

  printf '\n'
  _header_line "$term_width"
  printf '%s\n' "$title"
  _header_line "$term_width"
  printf 'Host: %s | Kernel: %s\n\n' "$host" "$kernel"
}
