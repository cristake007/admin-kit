#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/service.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  echo_info "This installs RabbitMQ from Debian repositories."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_package_installed rabbitmq-server; then
    echo_success "RabbitMQ is already installed."
  else
    apt_update
    apt_install rabbitmq-server
    echo_success "RabbitMQ installed."
  fi

  service_enable_now rabbitmq-server
  service_status_line rabbitmq-server
}

main "$@"
