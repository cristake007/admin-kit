#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
echo_info "This will install Ilias LMS with all necessary dependencies."
echo_info "This is a quick install script and may not cover all use cases."
echo_info "For production use, please refer to the official Ilias documentation."
echo ""

# Ensure env file exists
echo_info "Initializing environment file..."
run "scripts/custom/env_file.sh" || echo_error "Env file script failed"

# Basic system requirements
echo_info "Starting basic system requirements"
run "scripts/system/update_system.sh" || echo_error "Basic system requirements script failed"
run "scripts/system/set_timezone.sh" || echo_error "Timezone script failed"
run "scripts/system/set_hostname.sh" || echo_error "Hostname script failed"
run "scripts/system/create_user.sh" || echo_error "Create user script failed"


if ! confirm "Basic system requirements done, do you wish to continue?"; then
    echo_info "Cancelled."; exit 0
fi

# Ilias requirements installation
echo_info "Installing requirements..."
run "scripts/custom/create_directories.sh" || echo_error "Create directories script failed"
run "scripts/helper/install_common_tools.sh" || echo_error "Common tools installation script failed"
run "scripts/webserver/apache2.sh" || echo_error "Install Apache script failed"
run "scripts/helper/install_php.sh" || echo_error "Install PHP script failed"
run "scripts/databases/install_mariadb.sh" || echo_error "Install MariaDB script failed"

#Ilias specific requirements
run "scripts/custom/system_required_packages.sh" || echo_error "Ilias specific requirements script failed"
# Cleanup
apt clean && apt autocleans


#Run Ilias configs
#Install Ilias
#Configure VHOST
#Run Ilias hardening
}


main