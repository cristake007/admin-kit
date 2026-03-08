#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Ensure project .env file exists with secure permissions.
# Supports: linux
# Requires: write access to repo root
# Safe to rerun: yes
# Side effects: creates .env

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log

main() {
  local env_file="$PROJECT_ROOT/.env"
  if [[ -f "$env_file" ]]; then
    info "Environment file already exists: $env_file"
  else
    touch "$env_file"
    chmod 600 "$env_file"
    success "Created environment file: $env_file"
  fi
}

main "$@"
