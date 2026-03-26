#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

NODE_VERSION="20"
check_installed(){ command_exists node && node -v | grep -q "^v${NODE_VERSION}"; }
check_conflicts(){ return 0; }
install_step(){ apt_update; apt_install ca-certificates curl gnupg; curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -; apt_install nodejs; wf_mark_changed "Installed Node.js ${NODE_VERSION}.x"; }
summary_step(){ wf_default_summary "$1" "$2"; node -v || true; npm -v || true; }

main(){ echo_info "This installs Node.js from NodeSource."; read -r -p "Enter Node.js version (e.g., 18, 20) [20]: " NODE_VERSION; NODE_VERSION="${NODE_VERSION:-20}"; confirm "Continue with Node.js ${NODE_VERSION}.x installation?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "nodejs" check_installed check_conflicts install_step summary_step; }
main "$@"
