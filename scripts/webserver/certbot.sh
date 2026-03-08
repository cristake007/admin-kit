#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Install certbot and common webserver plugin package.
# Supports: debian, rhel, suse
# Requires: root privileges
# Safe to rerun: yes
# Side effects: package installation

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib os
require_lib pkg
require_lib core

main() {
  need_root
  os_detect
  os_require_supported

  local certbot_pkg="certbot"
  local plugin_pkg=""

  if [[ "$OS_FAMILY" == "arch" ]]; then
    error "Certbot helper script is not supported on arch in this toolkit."
    return 1
  fi

  if [[ "$OS_FAMILY" == "debian" ]]; then
    if pkg_is_installed apache2; then
      plugin_pkg="python3-certbot-apache"
    elif pkg_is_installed nginx; then
      plugin_pkg="python3-certbot-nginx"
    fi
  else
    if pkg_is_installed httpd; then
      plugin_pkg="python3-certbot-apache"
    elif pkg_is_installed nginx; then
      plugin_pkg="python3-certbot-nginx"
    fi
  fi

  pkg_update_index
  pkg_install "$certbot_pkg"
  if [[ -n "$plugin_pkg" ]]; then
    pkg_install "$plugin_pkg"
  else
    warn "No Apache/Nginx package detected; installed certbot only."
  fi

  success "Certbot installation completed."
}

main "$@"
