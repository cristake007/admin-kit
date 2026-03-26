#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/workflow.sh"
trap err_trap ERR

need_sudo || exit 1

check_installed() { apt_package_installed extrepo; }
check_conflicts() { return 0; }
install_step() {
  apt_update
  apt_install extrepo
  wf_mark_changed "Installed extrepo"
}
summary_step() {
  wf_default_summary "$1" "$2"
  dpkg -s extrepo 2>/dev/null | awk -F': ' '/^Version:/ {print "extrepo version: " $2}' || true
}

main() {
  echo_info "This installs 'extrepo' for managing external APT repositories."
  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }
  run_install_workflow "extrepo" check_installed check_conflicts install_step summary_step
}

main "$@"
