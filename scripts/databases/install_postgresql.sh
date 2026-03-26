#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
check_installed(){ apt_package_installed postgresql; }
check_conflicts(){ return 0; }
install_step(){ apt_update; apt_install postgresql postgresql-client; service_enable_now postgresql; wf_mark_changed "Installed PostgreSQL and enabled service"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line postgresql; pg_config --version || true; }
main(){ echo_info "This installs PostgreSQL (Debian default packages)."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "postgresql" check_installed check_conflicts install_step summary_step; }
main "$@"
