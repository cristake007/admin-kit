#!/usr/bin/env bash

[[ -n "${__LIB_SERVICE_SH:-}" ]] && return 0
__LIB_SERVICE_SH=1

service_is_active() {
  systemctl is-active --quiet "$1" 2>/dev/null
}

service_enable_now() {
  sudo systemctl enable --now "$1"
}

service_reload_or_restart() {
  local service="$1"
  sudo systemctl reload "$service" 2>/dev/null || sudo systemctl restart "$service"
}

service_status_line() {
  local service="$1"
  local active enabled
  active="$(systemctl is-active "$service" 2>/dev/null || echo inactive)"
  enabled="$(systemctl is-enabled "$service" 2>/dev/null || echo unknown)"
  echo_info "Status: ${active} | Enabled: ${enabled}"
}
