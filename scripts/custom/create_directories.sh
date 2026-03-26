#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/file.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

declare -A ILIAS_DIRECTORIES=( ["/opt/iliasdata"]="ILIASDATA main folder" ["/opt/iliasdata/log"]="ILIASDATA log subfolder" ["/opt/iliasdata/lucene"]="ILIASDATA lucene subfolder" ["/opt/iliasdata/errorlog"]="ILIASDATA errorlog subfolder" ["/opt/iliasdata/temp"]="ILIASDATA temp subfolder" ["/var/www/logs"]="ILIAS logs directory" ["/var/www/files"]="ILIAS web directory" ["/var/www/html"]="Apache2 web directory" )
check_installed(){ local d; for d in "${!ILIAS_DIRECTORIES[@]}"; do [[ -d "$d" ]] || return 1; done; return 0; }
check_conflicts(){ return 0; }
install_step(){ local d; for d in "${!ILIAS_DIRECTORIES[@]}"; do clean_and_create_directory "$d" "${ILIAS_DIRECTORIES[$d]}" || return 1; done; wf_mark_changed "Created/normalized ILIAS directories"; }
summary_step(){ wf_default_summary "$1" "$2"; }
main(){ echo_info "Manage ILIAS directories."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "create_directories" check_installed check_conflicts install_step summary_step; }
main "$@"
