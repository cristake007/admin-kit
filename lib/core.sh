#!/usr/bin/env bash

[[ -n "${__LIB_CORE_SH:-}" ]] && return 0
__LIB_CORE_SH=1

run() {
  local target="$1"; shift || true
  local caller_src="${BASH_SOURCE[1]:-unknown}"
  local caller_line="${BASH_LINENO[0]:-?}"

  if [[ ! -f "$target" && -n "${PROJECT_ROOT:-}" && -f "$PROJECT_ROOT/$target" ]]; then
    target="$PROJECT_ROOT/$target"
  fi

  if [[ ! -f "$target" ]]; then
    echo_error "Script not found: $target"
    echo_error "Called from ${caller_src}:${caller_line}"
    return 127
  fi

  local log="/tmp/$(basename "$target").$(date +%s).log"

  if bash "$target" "$@" > >(tee "$log") 2> >(tee -a "$log" >&2); then
    return 0
  else
    local rc=$?
    echo_error "$(basename "$target") failed (exit $rc)"
    echo_error "Called from ${caller_src}:${caller_line}"
    echo_error "Log: $log"
    tail -n 30 "$log" | sed 's/^/  /'
    return "$rc"
  fi
}

run_fatal() {
  run "$@" || { echo_error "Fatal: $(basename "$1") failed."; exit 1; }
}

err_trap() {
  local rc=$?
  local cmd=${BASH_COMMAND:-?}
  local src=${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}
  local line=${BASH_LINENO[0]:-?}
  echo_error "ERROR: rc=$rc at ${src}:${line}"
  echo_error "Command: $cmd"
  return "$rc"
}

need_sudo() {
  if [[ $EUID -ne 0 ]]; then
    echo_info "Elevating privileges with sudo..."
    sudo -v || { echo_error "sudo failed."; return 1; }
  fi
}

has_sudo_user() {
  local u uid
  while IFS=: read -r u _ uid _ _ _ _; do
    [[ "$uid" -ge 1000 && "$u" != "nobody" ]] || continue
    if id -nG "$u" 2>/dev/null | grep -Eq '(^|[[:space:]])(sudo|wheel)([[:space:]]|$)'; then
      return 0
    fi
  done </etc/passwd
  return 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

user_exists() {
  id -u "$1" >/dev/null 2>&1
}

run_step() {
  local step_name="$1"
  local preflight_fn="$2"
  local execute_fn="$3"
  local verify_fn="$4"

  echo_note "Step: ${step_name}"

  if ! eval "$preflight_fn"; then
    echo_error "Preflight failed for step: ${step_name}"
    return 1
  fi

  if ! eval "$execute_fn"; then
    echo_error "Execution failed for step: ${step_name}"
    return 1
  fi

  if ! eval "$verify_fn"; then
    echo_error "Verification failed for step: ${step_name}"
    return 1
  fi

  echo_success "Completed step: ${step_name}"
  return 0
}

always_ok() {
  return 0
}
