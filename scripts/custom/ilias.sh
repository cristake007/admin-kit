#!/usr/bin/env bash
set -Eeuo pipefail
# NON-INSTALLER: utility/orchestration script; not part of installer workflow contract.

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
trap err_trap ERR

need_sudo || exit 1

run_script_step() {
  local rel_path="$1"
  run "$rel_path"
}

main() {
  echo_info "This installs ILIAS LMS with required dependencies."
  echo_info "Quick install only. Review official ILIAS docs for production hardening."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  run_step "Initialize env file" always_ok "run_script_step scripts/custom/env_file.sh" always_ok
  run_step "Update operating system" always_ok "run_script_step scripts/system/update_system.sh" always_ok
  run_step "Set timezone" always_ok "run_script_step scripts/system/set_timezone.sh" always_ok
  run_step "Set hostname" always_ok "run_script_step scripts/system/set_hostname.sh" always_ok
  run_step "Create sudo user" always_ok "run_script_step scripts/system/create_user.sh" always_ok

  confirm "Basic system setup complete. Continue with ILIAS requirements?" || { echo_info "Cancelled."; exit 0; }

  run_step "Create required directories" always_ok "run_script_step scripts/custom/create_directories.sh" always_ok
  run_step "Install baseline utilities" always_ok "run_script_step scripts/system/common_packages.sh" always_ok
  run_step "Install Apache" always_ok "run_script_step scripts/webserver/apache2.sh" always_ok
  run_step "Install PHP" always_ok "run_script_step scripts/developer/install_php.sh" always_ok
  run_step "Install MariaDB" always_ok "run_script_step scripts/databases/install_mariadb.sh" always_ok
  run_step "Install required system packages" always_ok "run_script_step scripts/custom/system_required_packages.sh" always_ok

  sudo apt-get clean
  sudo apt-get autoclean -y

  echo_success "ILIAS prerequisites installed."
}

main "$@"
