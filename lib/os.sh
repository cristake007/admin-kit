#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_OS_SH:-}" ]] && return 0
__LIB_OS_SH=1

OS_ID=""
OS_ID_LIKE=""
OS_FAMILY="unsupported"
PKG_BACKEND=""
SERVICE_BACKEND="unknown"

os_detect() {
  if [[ ! -r /etc/os-release ]]; then
    OS_FAMILY="unsupported"
    return 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_ID_LIKE="${ID_LIKE:-}"

  local marker="${OS_ID} ${OS_ID_LIKE}"
  case "$marker" in
    *debian*|*ubuntu*)
      OS_FAMILY="debian"
      PKG_BACKEND="apt"
      ;;
    *rhel*|*fedora*|*rocky*|*almalinux*|*centos*)
      OS_FAMILY="rhel"
      if command -v dnf >/dev/null 2>&1; then
        PKG_BACKEND="dnf"
      elif command -v yum >/dev/null 2>&1; then
        PKG_BACKEND="yum"
      else
        PKG_BACKEND=""
      fi
      ;;
    *suse*|*opensuse*)
      OS_FAMILY="suse"
      PKG_BACKEND="zypper"
      ;;
    *arch*)
      OS_FAMILY="arch"
      PKG_BACKEND="pacman"
      ;;
    *)
      OS_FAMILY="unsupported"
      PKG_BACKEND=""
      ;;
  esac

  if command -v systemctl >/dev/null 2>&1; then
    SERVICE_BACKEND="systemd"
  fi
}

os_require_supported() {
  if [[ "$OS_FAMILY" == "unsupported" || -z "$PKG_BACKEND" ]]; then
    error "Unsupported Linux distribution: ID=${OS_ID:-unknown} ID_LIKE=${OS_ID_LIKE:-none}."
    return 1
  fi
}

os_family() {
  printf '%s\n' "$OS_FAMILY"
}
