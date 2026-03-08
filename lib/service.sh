#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_SERVICE_SH:-}" ]] && return 0
__LIB_SERVICE_SH=1

_service_require_systemd() {
  if [[ "$SERVICE_BACKEND" != "systemd" ]]; then
    error "Service management requires systemd on this host."
    return 1
  fi
}

service_exists() {
  local service_name="${1:?service required}"
  _service_require_systemd || return 1
  systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -Fxq "${service_name}.service"
}

service_is_active() {
  local service_name="${1:?service required}"
  _service_require_systemd || return 1
  systemctl is-active --quiet "$service_name"
}

service_is_enabled() {
  local service_name="${1:?service required}"
  _service_require_systemd || return 1
  systemctl is-enabled --quiet "$service_name"
}

service_enable_now() {
  local service_name="${1:?service required}"
  _service_require_systemd || return 1
  if service_exists "$service_name"; then
    local needs_enable=0
    local needs_start=0

    if service_is_enabled "$service_name"; then
      info "Service already enabled: $service_name"
    else
      needs_enable=1
    fi

    if service_is_active "$service_name"; then
      info "Service already active: $service_name"
    else
      needs_start=1
    fi

    if [[ "$needs_enable" -eq 0 && "$needs_start" -eq 0 ]]; then
      success "Service already enabled and active: $service_name"
      return 0
    fi

    if [[ "$needs_enable" -eq 1 && "$needs_start" -eq 1 ]]; then
      systemctl enable --now "$service_name"
      success "Service enabled and started: $service_name"
      return 0
    fi

    if [[ "$needs_enable" -eq 1 ]]; then
      systemctl enable "$service_name"
      success "Service enabled: $service_name"
    fi

    if [[ "$needs_start" -eq 1 ]]; then
      systemctl start "$service_name"
      success "Service started: $service_name"
    fi
  else
    warn "Service not found, skipped: $service_name"
  fi
}

service_restart_if_present() {
  local service_name="${1:?service required}"
  _service_require_systemd || return 1
  if service_exists "$service_name"; then
    systemctl restart "$service_name"
  else
    warn "Service not found, skipped restart: $service_name"
  fi
}
