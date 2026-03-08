#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install PHP runtime and common extensions.
# Supports: debian, rhel, suse, arch
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core
require_lib os
require_lib pkg

main() {
  need_root
  os_detect
  os_require_supported

  local packages_raw
  local -a packages=()
  packages_raw="$(os_resolve_pkg php_runtime_bundle)"
  read -r -a packages <<<"$packages_raw"

  pkg_update_index
  pkg_install "${packages[@]}"
  success "PHP packages installed."
}

main "$@"
