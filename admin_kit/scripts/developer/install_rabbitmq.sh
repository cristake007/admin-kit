#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

install_rabbitmq() {
  echo_note "Installing RabbitMQ from Debian repository..."
  apt_update
  apt_install rabbitmq-server

  systemctl enable --now rabbitmq-server
  echo_success "RabbitMQ installed and service enabled."
}

install_rabbitmq