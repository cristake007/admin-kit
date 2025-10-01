#!/usr/bin/env bash
set -Euo pipefail
trap err_trap ERR

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Bootstrap + functions
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require "functions/functions.sh"

echo_info "Creating project-root file"
touch .project-root
echo_info "Starting AdminKit"
bash admin_menu.sh
