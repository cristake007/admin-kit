#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1



main {

    # install_symfony_cli.sh
    # Installs Symfony CLI on Debian/Ubuntu systems (idempotent).

    if command -v symfony >/dev/null 2>&1; then
        ok "Symfony CLI is already installed: $(symfony -V | head -n1)"
    else
        note "Installing Symfony CLI..."
        curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash || die "Failed to add Symfony repo"
        sudo apt update -y
        sudo apt install -y symfony-cli || die "Symfony CLI installation failed"
        ok "Symfony CLI installed successfully: $(symfony -V | head -n1)"
    fi

}
