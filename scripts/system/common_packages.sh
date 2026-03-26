#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
PACKAGES=(curl wget git unzip zip ca-certificates gnupg lsb-release)
check_installed(){ local p; for p in "${PACKAGES[@]}"; do apt_package_installed "$p" || return 1; done; return 0; }
check_conflicts(){ return 0; }
install_step(){ local missing=() p; for p in "${PACKAGES[@]}"; do apt_package_installed "$p" || missing+=("$p"); done; [[ ${#missing[@]} -eq 0 ]] && return 0; apt_update; apt_install "${missing[@]}"; wf_mark_changed "Installed missing baseline packages: ${missing[*]}"; }
summary_step(){ wf_default_summary "$1" "$2"; }
main(){ echo_info "Install minimal baseline packages (shared by most scripts)."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "common_packages" check_installed check_conflicts install_step summary_step; }
main "$@"
