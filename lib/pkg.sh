#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_PKG_SH:-}" ]] && return 0
__LIB_PKG_SH=1

pkg_update_index() {
  case "$PKG_BACKEND" in
    apt) apt-get update -y ;;
    dnf) dnf makecache -y ;;
    yum) yum makecache -y ;;
    zypper) zypper --non-interactive refresh ;;
    pacman) pacman -Sy --noconfirm ;;
    *) error "Package backend is not supported on this distro."; return 1 ;;
  esac
}

pkg_is_installed() {
  local pkg="${1:?package required}"
  case "$PKG_BACKEND" in
    apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
    dnf|yum) rpm -q "$pkg" >/dev/null 2>&1 ;;
    zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
    pacman) pacman -Q "$pkg" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

pkg_install() {
  local to_install=()
  local pkg
  for pkg in "$@"; do
    if pkg_is_installed "$pkg"; then
      info "Package already installed: $pkg"
    else
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    success "Nothing to install."
    return 0
  fi

  case "$PKG_BACKEND" in
    apt) apt-get install -y "${to_install[@]}" ;;
    dnf) dnf install -y "${to_install[@]}" ;;
    yum) yum install -y "${to_install[@]}" ;;
    zypper) zypper --non-interactive install "${to_install[@]}" ;;
    pacman) pacman -S --noconfirm --needed "${to_install[@]}" ;;
    *) error "Package backend is not supported on this distro."; return 1 ;;
  esac
}

pkg_remove() {
  local to_remove=()
  local pkg
  for pkg in "$@"; do
    if pkg_is_installed "$pkg"; then
      to_remove+=("$pkg")
    else
      info "Package not installed: $pkg"
    fi
  done

  if [[ ${#to_remove[@]} -eq 0 ]]; then
    success "Nothing to remove."
    return 0
  fi

  case "$PKG_BACKEND" in
    apt) apt-get remove -y "${to_remove[@]}" ;;
    dnf) dnf remove -y "${to_remove[@]}" ;;
    yum) yum remove -y "${to_remove[@]}" ;;
    zypper) zypper --non-interactive remove "${to_remove[@]}" ;;
    pacman) pacman -R --noconfirm "${to_remove[@]}" ;;
    *) error "Package backend is not supported on this distro."; return 1 ;;
  esac
}

pkg_add_repo() {
  local name="${1:?repo name required}"
  local repo_line="${2:?repo line required}"

  case "$PKG_BACKEND" in
    apt)
      local list_file="/etc/apt/sources.list.d/${name}.list"
      if [[ -f "$list_file" ]] && grep -Fxq "$repo_line" "$list_file"; then
        info "APT repository already configured: $name"
        return 0
      fi
      printf '%s\n' "$repo_line" > "$list_file"
      ;;
    dnf|yum)
      local repo_file="/etc/yum.repos.d/${name}.repo"
      if [[ -f "$repo_file" ]] && grep -Fq "$repo_line" "$repo_file"; then
        info "YUM/DNF repository already configured: $name"
        return 0
      fi
      printf '%s\n' "$repo_line" > "$repo_file"
      ;;
    zypper)
      if zypper lr | awk '{print $3}' | grep -Fxq "$name"; then
        info "Zypper repository already configured: $name"
        return 0
      fi
      zypper --non-interactive ar "$repo_line" "$name"
      ;;
    pacman)
      error "pkg_add_repo is not implemented for pacman; configure /etc/pacman.conf manually."
      return 1
      ;;
    *)
      error "Repository setup is unsupported on this distro."
      return 1
      ;;
  esac
}


pkg_upgrade_system() {
  case "$PKG_BACKEND" in
    apt) apt-get upgrade -y && apt-get dist-upgrade -y ;;
    dnf) dnf upgrade -y ;;
    yum) yum update -y ;;
    zypper) zypper --non-interactive update ;;
    pacman) pacman -Syu --noconfirm ;;
    *) error "Package backend is not supported on this distro."; return 1 ;;
  esac
}
