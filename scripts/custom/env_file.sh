#!/usr/bin/env bash
set -Eeuo pipefail
# NON-INSTALLER: utility/orchestration script; not part of installer workflow contract.

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/env.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  ENV_VARS_FILE="${ENV_VARS_FILE:-$PROJECT_ROOT/.env}"
  initialize_env_file
}

main "$@"
