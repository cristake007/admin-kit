#!/usr/bin/env bash
set -Eeuo pipefail
# Compatibility shim: legacy path retained intentionally.

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../scripts/bootstrap.sh"
require_lib log
require_lib ui
require_lib os
require_lib pkg
require_lib service
require_lib file
require_lib validate
