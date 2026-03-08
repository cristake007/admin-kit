#!/usr/bin/env bash
set -Eeuo pipefail

BOOTSTRAP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$BOOTSTRAP_DIR/.." && pwd)"
export PROJECT_ROOT

# shellcheck disable=SC1091
source "$PROJECT_ROOT/lib/core.sh"
