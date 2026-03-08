#!/usr/bin/env bash

[[ -n "${__LIB_UI_SH:-}" ]] && return 0
__LIB_UI_SH=1

pause() {
  echo_info "Press Enter to continue..."
  read -r
}

confirm() {
  read -r -p "${1:-Proceed?} (Y/n): " ans
  [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

confirm_skip() {
  local prompt="${1:-Proceed?}"
  local ans
  while true; do
    read -r -p "${prompt} (y=yes / n=no / s=skip): " ans
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
  width=$(tput cols)
  padding=$(( (width - ${#text}) / 2 ))

  printf "\n%${padding}s${GREEN}%s${NC}%${padding}s\n\n" "" "$text" ""
  echo_info "Hostname: $(hostname)"
  echo_info "Kernel: $(uname -r)"
  echo_info "Uptime: $(uptime -p)"
  echo_info "Last Boot: $(who -b | awk '{print $3,$4}')"
  echo_info "CPU Model: $(lscpu | grep "Model name" | sed 's/Model name://' | xargs)"
  echo_info "CPU Cores: Physical: $(grep -c ^processor /proc/cpuinfo), Logical: $(nproc)"
  printf "%$(tput cols)s\n" | tr ' ' '-'
}
