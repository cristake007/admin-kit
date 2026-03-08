#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/file.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  declare -A ilias_directories=(
    ["/opt/iliasdata"]="ILIASDATA main folder"
    ["/opt/iliasdata/log"]="ILIASDATA log subfolder"
    ["/opt/iliasdata/lucene"]="ILIASDATA lucene subfolder"
    ["/opt/iliasdata/errorlog"]="ILIASDATA errorlog subfolder"
    ["/opt/iliasdata/temp"]="ILIASDATA temp subfolder"
    ["/var/www/logs"]="ILIAS logs directory"
    ["/var/www/files"]="ILIAS web directory"
    ["/var/www/html"]="Apache2 web directory"
  )

  local success_count=0 failed_count=0

  echo_info "ILIAS directory check:"
  for dir in "${!ilias_directories[@]}"; do
    if [[ -d "$dir" ]] && directory_has_content "$dir"; then
      echo_note "- $dir (${ilias_directories[$dir]}) exists and has content"
    else
      echo_note "- $dir (${ilias_directories[$dir]}) will be created"
    fi
  done

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  for dir in "${!ilias_directories[@]}"; do
    if clean_and_create_directory "$dir" "${ilias_directories[$dir]}"; then
      success_count=$((success_count + 1))
    else
      failed_count=$((failed_count + 1))
    fi
  done

  echo_info "Directories processed: $success_count"
  if (( failed_count > 0 )); then
    echo_error "Failed operations: $failed_count"
    exit 1
  fi
  echo_success "All directory operations completed successfully."
}

main "$@"
