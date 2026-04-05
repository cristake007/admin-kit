#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  local node_version
  echo_info "This installs Node.js from NodeSource."
  read -r -p "Enter Node.js version (e.g., 18, 20) [20]: " node_version
  node_version="${node_version:-20}"
  if ! [[ "$node_version" =~ ^[0-9]+$ ]]; then
    echo_error "Invalid Node.js major version: $node_version"
    exit 1
  fi

  confirm "Continue with Node.js ${node_version}.x installation?" || { echo_info "Cancelled."; exit 0; }

  if command_exists node && node -v | grep -q "^v${node_version}"; then
    echo_success "Node.js ${node_version}.x is already installed."
    node -v
    npm -v || true
    exit 0
  fi

  apt_update
  apt_install ca-certificates curl gnupg
  curl -fsSL "https://deb.nodesource.com/setup_${node_version}.x" | sudo -E bash -
  apt_install nodejs

  echo_success "Node.js installed."
  node -v || true
  npm -v || true
}

main "$@"
