#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  echo_info "This installs ILIAS LMS with required dependencies."
  echo_info "Quick install only. Review official ILIAS docs for production hardening."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  run "scripts/custom/env_file.sh"
  run "scripts/system/update_system.sh"
  run "scripts/system/set_timezone.sh"
  run "scripts/system/set_hostname.sh"
  run "scripts/system/create_user.sh"

  confirm "Basic system setup complete. Continue with ILIAS requirements?" || { echo_info "Cancelled."; exit 0; }

  run "scripts/custom/create_directories.sh"
  run "scripts/helper/install_common_tools.sh"
  run "scripts/webserver/apache2.sh"
  run "scripts/developer/install_php.sh"
  run "scripts/databases/install_mariadb.sh"
  run "scripts/custom/system_required_packages.sh"

  sudo apt-get clean
  sudo apt-get autoclean -y

  echo_success "ILIAS prerequisites installed."
}

main "$@"
