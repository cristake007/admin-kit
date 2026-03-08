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
  local pkgs=(curl wget git unzip zip ufw ca-certificates gnupg acl)
  local missing=()

  echo_info "This installs common command-line tools."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  for p in "${pkgs[@]}"; do
    apt_package_installed "$p" || missing+=("$p")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo_success "All common tools are already installed."
    return 0
  fi

  apt_update
  apt_install "${missing[@]}"
  echo_success "Common tools installed successfully."
}

main "$@"
