#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
check_installed(){ apt_package_installed mysql-server || apt_package_installed mysql-community-server; }
check_conflicts(){ ! apt_package_installed mariadb-server; }
install_step(){ apt_update; if ! apt_install mysql-server; then add_mysql_repo; apt_update; apt_install mysql-server; fi; service_enable_now mysql; wf_mark_changed "Installed MySQL and enabled service"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line mysql; }
main(){ echo_info "This installs Oracle MySQL Server."; echo_info "MySQL conflicts with MariaDB."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "mysql" check_installed check_conflicts install_step summary_step; }
main "$@"
