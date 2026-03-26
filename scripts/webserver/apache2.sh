#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
check_installed(){ apt_package_installed apache2; }
check_conflicts(){ ! apt_package_installed nginx; }
install_step(){ apt_update; apt_install apache2; service_enable_now apache2; wf_mark_changed "Installed Apache2 and enabled service"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line apache2; }
main(){ echo_info "This installs Apache2."; echo_info "Apache and Nginx conflict on ports 80/443."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "apache2" check_installed check_conflicts install_step summary_step; }
main "$@"
