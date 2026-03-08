#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_PKG_SH:-}" ]] && return 0
__LIB_PKG_SH=1

PKG_REFRESH_STALE_MINUTES_DEFAULT="${PKG_REFRESH_STALE_MINUTES_DEFAULT:-60}"
PKG_REFRESH_STATE_FILE_DEFAULT="${PKG_REFRESH_STATE_FILE_DEFAULT:-/var/cache/admin-kit/pkg-index-refresh.timestamp}"

pkg_refresh_mode_is_valid() {
  local mode="${1:?mode required}"
  case "$mode" in
    auto|always|never|prompt) return 0 ;;
    *) return 1 ;;
  esac
}

pkg_refresh_state_file() {
  local state_file="$PKG_REFRESH_STATE_FILE_DEFAULT"

  if [[ -n "${PKG_REFRESH_STATE_FILE:-}" ]]; then
    state_file="$PKG_REFRESH_STATE_FILE"
  fi

  printf '%s\n' "$state_file"
}

pkg_refresh_mark_now() {
  local state_file
  state_file="$(pkg_refresh_state_file)"

  mkdir -p "$(dirname -- "$state_file")"
  date +%s > "$state_file"

  export PKG_INDEX_REFRESHED=1
  export PKG_INDEX_REFRESH_TS="$(cat "$state_file")"
}

pkg_refresh_last_ts() {
  local state_file
  state_file="$(pkg_refresh_state_file)"

  if [[ -n "${PKG_INDEX_REFRESH_TS:-}" ]] && [[ "${PKG_INDEX_REFRESH_TS}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$PKG_INDEX_REFRESH_TS"
    return 0
  fi

  if [[ -r "$state_file" ]]; then
    local ts
    ts="$(<"$state_file")"
    if [[ "$ts" =~ ^[0-9]+$ ]]; then
      printf '%s\n' "$ts"
      return 0
    fi
  fi

  return 1
}

pkg_refresh_is_stale() {
  local stale_minutes="${1:-$PKG_REFRESH_STALE_MINUTES_DEFAULT}"
  local now_ts last_ts max_age

  if ! [[ "$stale_minutes" =~ ^[0-9]+$ ]]; then
    error "Invalid stale minutes value: $stale_minutes"
    return 1
  fi

  if ! last_ts="$(pkg_refresh_last_ts)"; then
    return 0
  fi

  now_ts="$(date +%s)"
  max_age=$((stale_minutes * 60))
  (( now_ts - last_ts >= max_age ))
}

pkg_refresh_index() {
  local mode="auto"
  local stale_minutes="$PKG_REFRESH_STALE_MINUTES_DEFAULT"
  local reason="package operations"
  local explicit_mode="${PKG_REFRESH_MODE:-}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        mode="${2:?mode value required}"
        shift 2
        ;;
      --stale-minutes)
        stale_minutes="${2:?stale-minutes value required}"
        shift 2
        ;;
      --reason)
        reason="${2:?reason value required}"
        shift 2
        ;;
      *)
        error "Unknown pkg_refresh_index argument: $1"
        return 1
        ;;
    esac
  done

  if [[ -n "$explicit_mode" ]]; then
    mode="$explicit_mode"
  fi

  if ! pkg_refresh_mode_is_valid "$mode"; then
    error "Invalid package refresh mode: $mode (supported: auto, always, never, prompt)"
    return 1
  fi

  if [[ -n "${PKG_INDEX_REFRESHED:-}" ]]; then
    info "Package index refresh policy: skipping refresh for $reason (already refreshed in this workflow)."
    return 0
  fi

  case "$mode" in
    never)
      info "Package index refresh policy: skipping refresh for $reason (mode: never)."
      return 0
      ;;
    always)
      info "Package index refresh policy: refreshing now for $reason (mode: always)."
      pkg_update_index
      pkg_refresh_mark_now
      return 0
      ;;
    prompt)
      info "Package index refresh policy: operator prompt requested for $reason (mode: prompt)."
      if declare -F confirm >/dev/null 2>&1; then
        if ! confirm "Refresh package metadata before proceeding with $reason?"; then
          info "Package index refresh skipped by operator for $reason."
          return 0
        fi
        info "Refreshing package metadata for $reason after operator confirmation."
        pkg_update_index
        pkg_refresh_mark_now
        return 0
      fi

      warn "Prompt mode requested but no confirm() helper is loaded. Falling back to mode: auto."
      mode="auto"
      ;;
  esac

  if pkg_refresh_is_stale "$stale_minutes"; then
    info "Package index refresh policy: refreshing now for $reason (mode: auto, stale threshold ${stale_minutes}m)."
    pkg_update_index
    pkg_refresh_mark_now
    return 0
  fi

  info "Package index refresh policy: skipping refresh for $reason (mode: auto, cache age within ${stale_minutes}m)."
}

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
