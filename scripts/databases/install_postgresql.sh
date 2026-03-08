#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
  echo_info "This will install PostgreSQL (Debian 12 default)."
  echo_info "After installation, the PostgreSQL service will be enabled and started."

  if ! confirm "Do you want to continue?"; then
    echo_info "Cancelled."; exit 0
  fi

  if apt_is_installed postgresql; then
    echo_success "PostgreSQL is already installed."
    sudo systemctl enable --now postgresql
    pg_config --version
    exit 0
  fi

  apt_update
  apt_install postgresql postgresql-client
  sudo systemctl enable --now postgresql
  echo_success "PostgreSQL installed and started."
  echo_info "Status: $(systemctl is-active postgresql) | Enabled: $(systemctl is-enabled postgresql 2>/dev/null || echo unknown)"
  pg_config --version
}

main
