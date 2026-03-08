#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  read -r -p "Enter Node.js version (e.g., 18, 20) [20]: " NODE_VERSION
  NODE_VERSION="${NODE_VERSION:-20}"

  echo_note "Installing Node.js ${NODE_VERSION}.x from NodeSource..."
  apt_update
  apt_install ca-certificates curl gnupg
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -
  apt_install nodejs

  echo_success "Node.js installed."
  node -v || true
  npm -v || true
}

main