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
  if ! command -v node >/dev/null 2>&1; then
    return 1
  fi

  local version raw_major
  version="$(node -v 2>/dev/null || true)"
  raw_major="${version#v}"
  raw_major="${raw_major%%.*}"

  if [[ "$raw_major" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$raw_major"
    return 0
  fi

  return 1
}

show_preinstall_message() {
  info "This action will install Node.js using distro packages or an optional NodeSource track."
  info "Prerequisites: root privileges, network access, and package repository connectivity."
  info "- Default track: install distro package versions (recommended for maximum distro compatibility)."
  if [[ "$OS_FAMILY" == "debian" || "$OS_FAMILY" == "rhel" ]]; then
    info "- Major track: install a selected Node.js major (18/20/22) from NodeSource repository."
  else
    info "- Major track: not available on this distro family ($OS_FAMILY)."
  fi
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
      *)
        error "Invalid selection: ${choice}."
        return 1
        ;;
    esac
  else
    info "Using distro default track because NodeSource major tracks are not supported on this distro family."
  fi

  printf '%s\n' "$selected_track"
}

track_is_supported() {
  local selected_track="${1:?track required}"

  if [[ "$selected_track" == "$NODE_TRACK_DEFAULT" ]]; then
    return 0
  fi

  if [[ "$OS_FAMILY" == "debian" || "$OS_FAMILY" == "rhel" ]]; then
    return 0
  fi

  error "Selected Node.js major track ($selected_track) is unsupported on distro family '$OS_FAMILY'. Use the distro default track on this system."
  return 1
}

selected_track_satisfied() {
  local selected_track="${1:?track required}"
  local current_major

  current_major="$(node_current_major || true)"
  if [[ -z "$current_major" ]]; then
    return 1
  fi

  if [[ "$selected_track" == "$NODE_TRACK_DEFAULT" ]]; then
    info "Node.js is already installed (major $current_major)."
    return 0
  fi

  if [[ "$current_major" == "$selected_track" ]]; then
    info "Installed Node.js major ($current_major) already matches selected target ($selected_track)."
    return 0
  fi

  return 1
}

configure_nodesource_repo() {
  local selected_major="${1:?major required}"
  local setup_script="/tmp/nodesource_setup_${selected_major}.sh"

  info "Configuring NodeSource repository for Node.js ${selected_major}.x"
  curl -fsSL "https://deb.nodesource.com/setup_${selected_major}.x" -o "$setup_script"
  bash "$setup_script"
  rm -f "$setup_script"
}

run_checks() {
  need_root
  os_detect
  os_require_supported

  NODE_SELECTED_TRACK="$(choose_track)"
  track_is_supported "$NODE_SELECTED_TRACK"

  if selected_track_satisfied "$NODE_SELECTED_TRACK"; then
    success "No installation changes required."
    verify_section "Node.js toolchain"
    verify_command "node -v" node -v || true
    verify_command "npm -v" npm -v || true
    NODE_SKIP_INSTALL=1
    return 0
  fi
}

run_install() {
  if [[ "$NODE_SKIP_INSTALL" -eq 1 ]]; then
    info "Skipping Node.js install stage; target already satisfied."
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

post_install() {
  verify_section "Node.js toolchain"
  verify_command "node -v" node -v || true
  verify_command "npm -v" npm -v || true
}

main() {
  run_install_workflow \
    "Node.js installation" \
    "Proceed with Node.js installation?" \
    show_preinstall_message \
    run_checks \
    run_install \
    post_install
}

main "$@"
