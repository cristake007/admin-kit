#!/usr/bin/env bash

[[ -n "${__LIB_UI_SH:-}" ]] && return 0
__LIB_UI_SH=1

pause() {
  echo_info "Press Enter to continue..."
  read -r
}

confirm() {
  local prompt="${1:-Proceed?}"
  local ans
  printf "%s (Y/n): " "$prompt"
  read -r ans
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

confirm_skip() {
  local prompt="${1:-Proceed?}"
  local ans
  while true; do
    printf "%s (y=yes / n=no / s=skip): " "$prompt"
    read -r ans
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
  local width padding hostname_val kernel_val uptime_val last_boot cpu_model cpu_cores
  width="$(tput cols 2>/dev/null || echo 80)"
  [[ "$width" =~ ^[0-9]+$ ]] || width=80
  (( width > 20 )) || width=80
  padding=$(( (width - ${#text}) / 2 ))
  (( padding < 0 )) && padding=0

  hostname_val="$(hostname 2>/dev/null || echo "unknown")"
  kernel_val="$(uname -r 2>/dev/null || echo "unknown")"
  uptime_val="$(uptime -p 2>/dev/null || echo "unavailable")"
  last_boot="$(who -b 2>/dev/null | awk '{print $3,$4}' || true)"
  [[ -n "$last_boot" ]] || last_boot="unavailable"
  cpu_model="$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}' || true)"
  [[ -n "$cpu_model" ]] || cpu_model="unavailable"
  cpu_cores="$(nproc 2>/dev/null || echo "unknown")"

  printf "\n%${padding}s${GREEN}%s${NC}%${padding}s\n\n" "" "$text" ""
  echo_info "Hostname: ${hostname_val}"
  echo_info "Kernel: ${kernel_val}"
  echo_info "Uptime: ${uptime_val}"
  echo_info "Last Boot: ${last_boot}"
  echo_info "CPU Model: ${cpu_model}"
  echo_info "CPU Cores: ${cpu_cores}"
  printf "%${width}s\n" | tr ' ' '-'
}
