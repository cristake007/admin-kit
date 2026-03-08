#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_note "Installing Valkey (server + tools) from Debian repository..."
  apt_update
  apt_install valkey-server valkey-tools

  systemctl enable --now valkey-server
  echo_success "Valkey installed and service enabled."
}

main