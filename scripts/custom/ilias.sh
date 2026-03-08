#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

preflight_required_scripts() {
  local missing=0
  local target

  for target in "$@"; do
    if [[ ! -f "$target" ]]; then
      echo_error "Required script not found: $target"
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    echo_error "Preflight failed. Aborting before making changes."
    exit 1
  fi
}

main() {
echo_info "This will install Ilias LMS with all necessary dependencies."
echo_info "This is a quick install script and may not cover all use cases."
echo_info "For production use, please refer to the official Ilias documentation."
echo ""

local -a required_scripts=(
  "scripts/custom/env_file.sh"
  "scripts/system/update_system.sh"
  "scripts/system/set_timezone.sh"
  "scripts/system/set_hostname.sh"
  "scripts/system/create_user.sh"
  "scripts/custom/create_directories.sh"
  "scripts/helper/install_common_tools.sh"
  "scripts/webserver/apache2.sh"
  "scripts/developer/install_php.sh"
  "scripts/databases/install_mariadb.sh"
  "scripts/custom/system_required_packages.sh"
)

preflight_required_scripts "${required_scripts[@]}"

# Ensure env file exists
echo_info "Initializing environment file..."
run "scripts/custom/env_file.sh"

# Basic system requirements
echo_info "Starting basic system requirements"
run "scripts/system/update_system.sh"
run "scripts/system/set_timezone.sh"
run "scripts/system/set_hostname.sh"
run "scripts/system/create_user.sh"


if ! confirm "Basic system requirements done, do you wish to continue?"; then
    echo_info "Cancelled."; exit 0
fi

# Ilias requirements installation
echo_info "Installing requirements..."
run "scripts/custom/create_directories.sh"
run "scripts/helper/install_common_tools.sh"
run "scripts/webserver/apache2.sh"
run "scripts/developer/install_php.sh"
run "scripts/databases/install_mariadb.sh"

#Ilias specific requirements
run "scripts/custom/system_required_packages.sh"
# Cleanup
if command_exists apt-get; then
  sudo apt-get clean
  sudo apt-get autoclean -y
fi


#Run Ilias configs
#Install Ilias
#Configure VHOST
#Run Ilias hardening
}


main
