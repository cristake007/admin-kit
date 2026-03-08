#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install packages commonly needed by ILIAS.
# Supports: debian, rhel, suse
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

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "ILIAS required package bundle is not supported on arch in this toolkit."
    return 1
  fi

  pkg_update_index
  pkg_install imagemagick ghostscript ffmpeg clamav maven
  success "Installed core ILIAS required packages."
}

main "$@"
