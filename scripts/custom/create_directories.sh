#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Create ILIAS working directories.
# Supports: linux
# Requires: root privileges
# Safe to rerun: yes
# Side effects: directory creation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core

main() {
  need_root
  local dirs=(/var/www/ilias /var/www/ilias/data /var/log/ilias)
  local dir
  for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      info "Directory already exists: $dir"
    else
      mkdir -p "$dir"
      success "Created directory: $dir"
    fi
  done
}

main "$@"
