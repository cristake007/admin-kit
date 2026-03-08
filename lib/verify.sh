#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_VERIFY_SH:-}" ]] && return 0
__LIB_VERIFY_SH=1

verify_section() {
  local title="${1:?section title required}"
  printf '\n'
  info "Verification: ${title}"
}

verify_item() {
  local label="${1:?label required}"
  local value="${2:-<empty>}"
  info "- ${label}: ${value}"
}

verify_warning() {
  local label="${1:?label required}"
  local detail="${2:?detail required}"
  warn "- ${label}: ${detail}"
}

verify_command() {
  local label="${1:?label required}"
  shift
  local bin="${1:?command required}"

  if ! command -v "$bin" >/dev/null 2>&1; then
    verify_warning "$label" "command not found: $bin"
    return 1
  fi

  local output=""
  if output="$("$@" 2>/dev/null | head -n1)" && [[ -n "$output" ]]; then
    verify_item "$label" "$output"
    return 0
  fi

  verify_warning "$label" "command failed: $*"
  return 1
}

verify_systemd_service() {
  local service_name="${1:?service name required}"

  if ! command -v systemctl >/dev/null 2>&1; then
    verify_warning "service ${service_name}" "systemctl not available"
    return 1
  fi

  if ! systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -Fxq "${service_name}.service"; then
    verify_warning "service ${service_name}" "unit not found"
    return 1
  fi

  local active_state enabled_state
  active_state="$(systemctl is-active "$service_name" 2>/dev/null || true)"
  enabled_state="$(systemctl is-enabled "$service_name" 2>/dev/null || true)"

  verify_item "service ${service_name}" "active=${active_state:-unknown}, enabled=${enabled_state:-unknown}"
  return 0
}
