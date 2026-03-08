#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Ensure project .env file exists with secure permissions.
# Supports: linux
# Requires: write access to repo root
# Safe to rerun: yes
# Side effects: creates or normalizes .env permissions

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib env

main() {
  ensure_env_file "$PROJECT_ROOT/.env"
}

main "$@"
