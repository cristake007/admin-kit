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

  local packages=()
  case "$OS_FAMILY" in
    debian) packages=(php php-cli php-mysql php-xml php-mbstring php-zip php-curl) ;;
    rhel) packages=(php php-cli php-mysqlnd php-xml php-mbstring php-zip php-curl) ;;
    suse) packages=(php8 php8-cli php8-mysql php8-xmlreader php8-mbstring php8-zip php8-curl) ;;
    arch) packages=(php php-apache) ;;
  esac

  pkg_update_index
  pkg_install "${packages[@]}"
  success "PHP packages installed."
}

main "$@"
