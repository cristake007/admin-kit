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

confirm_proceed() {
  local prompt="${1:-Proceed with these changes?}"
  confirm "$prompt"
}

operator_aborted() {
  warn "Aborted by operator."
}

_header_line() {
  local width="${1:-0}"
  if [[ "$width" -ge 20 ]]; then
    printf '%*s\n' "$width" '' | tr ' ' '='
  else
    printf '========================================\n'
  fi
}

_print_centered() {
  local text="$1"
  local width="$2"
  local text_len=0
  local padding=0

  if ! [[ "$width" =~ ^[0-9]+$ ]] || (( width <= 0 )); then
    printf '%s\n' "$text"
    return
  fi

  text_len=${#text}
  if (( text_len >= width )); then
    printf '%s\n' "$text"
    return
  fi

  padding=$(((width - text_len) / 2))
  printf '%*s%s\n' "$padding" '' "$text"
}

_os_pretty_name() {
  local pretty="unknown"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    pretty="${PRETTY_NAME:-unknown}"
  fi
  printf '%s\n' "$pretty"
}

_uptime_human() {
  local uptime_text="unknown"
  if command -v uptime >/dev/null 2>&1; then
    uptime_text="$(uptime -p 2>/dev/null || true)"
    uptime_text="${uptime_text#up }"
  fi
  if [[ -z "$uptime_text" || "$uptime_text" == "unknown" ]] && [[ -r /proc/uptime ]]; then
    local total_seconds
    total_seconds="$(cut -d'.' -f1 /proc/uptime 2>/dev/null || echo '')"
    if [[ "$total_seconds" =~ ^[0-9]+$ ]]; then
      uptime_text="${total_seconds}s"
    fi
  fi
  printf '%s\n' "${uptime_text:-unknown}"
}

_primary_ip() {
  local ip="unknown"
  if command -v hostname >/dev/null 2>&1; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  printf '%s\n' "${ip:-unknown}"
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

  local os_name=""
  local uptime_text=""
  local primary_ip=""
  os_name="$(_os_pretty_name)"
  uptime_text="$(_uptime_human)"
  primary_ip="$(_primary_ip)"

  printf '\n'
  _header_line "$term_width"
  _print_centered "ADMIN KIT :: $title" "$term_width"
  _header_line "$term_width"
  printf 'Host: %s\n' "$host"
  printf 'OS: %s\n' "$os_name"
  printf 'Kernel: %s\n' "$kernel"
  printf 'IP: %s\n' "$primary_ip"
  printf 'Uptime: %s\n\n\n' "$uptime_text"
}
