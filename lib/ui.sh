#!/usr/bin/env bash

[[ -n "${__LIB_UI_SH:-}" ]] && return 0
__LIB_UI_SH=1

ui_term_width() {
  local width="${COLUMNS:-}"
  if [[ -z "$width" || ! "$width" =~ ^[0-9]+$ || "$width" -lt 20 ]]; then
    if command -v tput >/dev/null 2>&1; then
      width="$(tput cols 2>/dev/null || true)"
    fi
  fi
  if [[ -z "$width" || ! "$width" =~ ^[0-9]+$ || "$width" -lt 20 ]]; then
    width=80
  fi
  printf '%s\n' "$width"
}

safe_cmd_output() {
  local fallback="$1"
  shift
  local out
  out="$("$@" 2>/dev/null || true)"
  [[ -n "$out" ]] && printf '%s\n' "$out" || printf '%s\n' "$fallback"
}

pause() {
  if [[ ! -t 0 ]]; then
    return 0
  fi
  echo_info "Press Enter to continue..."
  read -r || true
}

confirm() {
  local prompt="${1:-Proceed?}"
  local ans

  if [[ ! -t 0 ]]; then
    return 0
  fi

  printf "%s (Y/n): " "$prompt"
  if ! read -r ans; then
    return 1
  fi
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

confirm_skip() {
  local prompt="${1:-Proceed?}"
  local ans

  if [[ ! -t 0 ]]; then
    return 0
  fi

  while true; do
    printf "%s (y=yes / n=no / s=skip): " "$prompt"
    if ! read -r ans; then
      return 1
    fi

    case "$ans" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      [Ss]) return 2 ;;
      *) echo_error "Please enter y, n, or s." ;;
    esac
  done
}

display_header() {
  local text="$1"
  local width padding
  local host kernel uptime_text last_boot cpu_model cpu_cores

  width="$(ui_term_width)"
  padding=$(( (width - ${#text}) / 2 ))
  (( padding < 0 )) && padding=0

  host="$(safe_cmd_output "unknown" hostname)"
  kernel="$(safe_cmd_output "unknown" uname -r)"
  uptime_text="$(safe_cmd_output "unknown" uptime -p)"
  last_boot="$(safe_cmd_output "unknown" bash -lc "who -b | sed -E 's/.*system boot[[:space:]]+//'")"
  cpu_model="$(safe_cmd_output "unknown" bash -lc "lscpu | awk -F: '/Model name/ {gsub(/^ +/,\"\",\$2); print \$2; exit}'")"
  cpu_cores="$(safe_cmd_output "unknown" nproc)"

  printf "\n%${padding}s${GREEN}%s${NC}%${padding}s\n\n" "" "$text" ""
  echo_info "Hostname: ${host}"
  echo_info "Kernel: ${kernel}"
  echo_info "Uptime: ${uptime_text}"
  echo_info "Last Boot: ${last_boot}"
  echo_info "CPU Model: ${cpu_model}"
  echo_info "CPU Cores (logical): ${cpu_cores}"
  printf "%${width}s\n" | tr ' ' '-'
}
