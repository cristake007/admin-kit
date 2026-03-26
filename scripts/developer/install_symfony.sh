#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

check_installed(){ command_exists symfony; }
check_conflicts(){ return 0; }
install_step(){ apt_update; apt_install ca-certificates curl gnupg; curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash; apt_update; apt_install symfony-cli; wf_mark_changed "Installed Symfony CLI"; }
summary_step(){ wf_default_summary "$1" "$2"; symfony -V | head -n1 || true; }

main(){ echo_info "This installs Symfony CLI."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "symfony" check_installed check_conflicts install_step summary_step; }
main "$@"
