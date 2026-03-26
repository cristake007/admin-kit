#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
check_installed(){ apt_package_installed nginx; }
check_conflicts(){ ! apt_package_installed apache2; }
install_step(){ apt_update; apt_install nginx; service_enable_now nginx; service_is_active nginx; wf_mark_changed "Installed Nginx and enabled service"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line nginx; }
main(){ echo_info "This installs Nginx."; echo_info "Apache and Nginx conflict on ports 80/443."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "nginx" check_installed check_conflicts install_step summary_step; }
main "$@"
