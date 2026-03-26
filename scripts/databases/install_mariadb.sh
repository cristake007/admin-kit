#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
check_installed(){ apt_package_installed mariadb-server; }
check_conflicts(){
  if apt_package_installed mysql-server || apt_package_installed mysql-community-server; then
    echo_error "MySQL is already installed. MariaDB conflicts with MySQL."
    return 1
  fi
  return 0
}
install_step(){ apt_update; apt_install mariadb-server mariadb-client; service_enable_now mariadb; wf_mark_changed "Installed MariaDB and enabled service"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line mariadb; }
main(){
  echo_info "This installs MariaDB (server and client)."
  echo_info "MariaDB conflicts with MySQL."
  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }
  if ! run_install_workflow "mariadb" check_installed check_conflicts install_step summary_step; then
    exit 1
  fi
}
main "$@"
