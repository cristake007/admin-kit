#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

print_symfony_version() {
  local version
  version="$(symfony version 2>/dev/null | head -n1 || true)"
  if [[ -z "$version" ]]; then
    version="$(symfony -V 2>/dev/null | head -n1 || true)"
  fi

  if [[ -n "$version" ]]; then
    echo_note "$version"
  fi
}

install_symfony_cli() {
  if command -v symfony >/dev/null 2>&1; then
    echo_success "Symfony CLI is already installed."
    print_symfony_version
    return 0
  fi

  echo_note "Installing Symfony CLI..."

  apt_update
  apt_install ca-certificates curl

  if ! curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash; then
    echo_error "Failed to configure Symfony repository."
    return 1
  fi

  apt_update
  apt_install symfony-cli

  if ! command -v symfony >/dev/null 2>&1; then
    echo_error "Symfony CLI installation completed but 'symfony' is not available on PATH."
    return 1
  fi

  echo_success "Symfony CLI installed successfully."
  print_symfony_version
}

main() {
  install_symfony_cli
}

main "$@"
