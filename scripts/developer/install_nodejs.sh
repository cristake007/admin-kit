#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install Node.js and npm from distro packages or NodeSource major tracks.
# Supports: debian, rhel, suse, arch (NodeSource major track only on debian/rhel)
# Requires: root privileges, network access for package install
# Safe to rerun: yes
# Side effects: package installation, optional repository configuration

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib os
require_lib pkg
require_lib ui
require_lib verify
require_lib install

NODE_TRACK_DEFAULT="default"
NODE_SELECTED_TRACK="$NODE_TRACK_DEFAULT"
NODE_SKIP_INSTALL=0

node_current_major() {
  command -v node >/dev/null 2>&1 || return 1
  local version raw_major
  version="$(node -v 2>/dev/null || true)"
  raw_major="${version#v}"
  raw_major="${raw_major%%.*}"
  [[ "$raw_major" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$raw_major"
}

show_message() {
  info "This action will install Node.js using distro packages or an optional NodeSource major track."
}

choose_track() {
  local selected_track="$NODE_TRACK_DEFAULT"

  if [[ "$OS_FAMILY" == "debian" || "$OS_FAMILY" == "rhel" ]]; then
    printf '\nChoose Node.js source:\n'
    printf '  1) Distro default package\n'
    printf '  2) NodeSource major 18\n'
    printf '  3) NodeSource major 20\n'
    printf '  4) NodeSource major 22\n'

    local choice
    read -r -p "Selection [1-4, default 1]: " choice
    case "${choice:-1}" in
      1) selected_track="$NODE_TRACK_DEFAULT" ;;
      2) selected_track="18" ;;
      3) selected_track="20" ;;
      4) selected_track="22" ;;
      *) error "Invalid selection: ${choice}."; return 1 ;;
    esac
  fi

  printf '%s\n' "$selected_track"
}

run_prereq_checks() {
  need_root
  os_detect
  os_require_supported
  NODE_SELECTED_TRACK="$(choose_track)"

  if [[ "$NODE_SELECTED_TRACK" != "$NODE_TRACK_DEFAULT" && "$OS_FAMILY" != "debian" && "$OS_FAMILY" != "rhel" ]]; then
    error "Selected Node.js major track ($NODE_SELECTED_TRACK) is unsupported on distro family '$OS_FAMILY'."
    return 1
  fi
}

check_already_installed() {
  local current_major
  current_major="$(node_current_major || true)"
  [[ -n "$current_major" ]] || return 0

  if [[ "$NODE_SELECTED_TRACK" == "$NODE_TRACK_DEFAULT" || "$current_major" == "$NODE_SELECTED_TRACK" ]]; then
    NODE_SKIP_INSTALL=1
    info "Node.js target already satisfied (major ${current_major})."
  fi
}

check_conflicts() { info "No explicit Node.js conflicts detected."; }

show_install_plan() {
  if [[ "$NODE_SELECTED_TRACK" == "$NODE_TRACK_DEFAULT" ]]; then
    verify_item "track" "distro default"
    verify_item "packages" "nodejs npm"
  else
    verify_item "track" "NodeSource $NODE_SELECTED_TRACK.x"
    verify_item "package" "nodejs"
  fi
}

configure_nodesource_repo() {
  local selected_major="${1:?major required}"
  local setup_script="/tmp/nodesource_setup_${selected_major}.sh"
  curl -fsSL "https://deb.nodesource.com/setup_${selected_major}.x" -o "$setup_script"
  bash "$setup_script"
  rm -f "$setup_script"
}

run_install() {
  if [[ "$NODE_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping installation; target already satisfied."
    return 0
  fi

  pkg_refresh_index --reason "nodejs installation prerequisites"

  if [[ "$NODE_SELECTED_TRACK" == "$NODE_TRACK_DEFAULT" ]]; then
    pkg_install nodejs npm
    return 0
  fi

  configure_nodesource_repo "$NODE_SELECTED_TRACK"
  pkg_refresh_index --mode always --reason "nodesource repository metadata"
  pkg_install nodejs
}

run_service_config() { info "No service configuration required for Node.js."; }

post_install_verify() {
  verify_section "Post-install verification"
  verify_command "node -v" node -v || true
  verify_command "npm -v" npm -v || true
}

final_summary() { success "Node.js installation workflow finished."; }

main() {
  run_install_workflow \
    "Node.js installation" \
    "Proceed with Node.js installation?" \
    show_message run_prereq_checks check_already_installed check_conflicts show_install_plan run_install run_service_config post_install_verify final_summary
}

main "$@"
