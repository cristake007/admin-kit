#!/usr/bin/env bash

[[ -n "${__LIB_PKG_SH:-}" ]] && return 0
__LIB_PKG_SH=1

export DEBIAN_FRONTEND=noninteractive

apt_update() { sudo apt-get update -y; }

apt_upgrade() {
  sudo apt-get -o Dpkg::Options::="--force-confdef" \
               -o Dpkg::Options::="--force-confold" \
               dist-upgrade -y
}

apt_install() { sudo apt-get install -y "$@"; }
apt_remove() { sudo apt-get remove -y "$@"; }

install_items() {
  local kind="${1:-package}"
  shift || true
  if [[ $# -eq 0 ]]; then
    echo_error "No ${kind}s specified."
    return 1
  fi
  apt_update
  apt_install "$@"
}

# Strict Debian package-state check (dpkg only)
apt_package_installed() {
  local package_name="$1"
  dpkg-query -W -f='${Status}\n' "$package_name" 2>/dev/null | grep -qx 'install ok installed'
}

# Broad installed-item check (any supported install path/source)
item_is_installed() {
  local name="$1"

  if apt_package_installed "$name"; then
    return 0
  fi

  if command -v "$name" >/dev/null 2>&1; then
    return 0
  fi

  if [[ -x "/usr/local/bin/$name" ]]; then
    return 0
  fi

  if systemctl list-unit-files 2>/dev/null | grep -q "^${name}\.service"; then
    return 0
  fi

  if command -v snap >/dev/null 2>&1 && snap list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$name"; then
    return 0
  fi

  if command -v flatpak >/dev/null 2>&1 && flatpak list 2>/dev/null | awk -F'\t' '{print $1}' | grep -qx "$name"; then
    return 0
  fi

  return 1
}

add_mysql_repo() {
  local list_file="/etc/apt/sources.list.d/mysql.list"
  local keyring_file="/usr/share/keyrings/mysql-apt.gpg"
  echo_note "Adding Oracle MySQL APT repository (8.4 LTS)..."
  curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | sudo gpg --dearmor -o "$keyring_file"
  echo "deb [signed-by=$keyring_file] http://repo.mysql.com/apt/debian/ bookworm mysql-8.4-lts mysql-tools" \
    | sudo tee "$list_file" >/dev/null
}
