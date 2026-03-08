#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_LOG_SH:-}" ]] && return 0
__LIB_LOG_SH=1

if [[ -t 1 ]]; then
  _LOG_RED='\033[0;31m'
  _LOG_GREEN='\033[0;32m'
  _LOG_YELLOW='\033[0;33m'
  _LOG_CYAN='\033[0;36m'
  _LOG_RESET='\033[0m'
else
  _LOG_RED=''
  _LOG_GREEN=''
  _LOG_YELLOW=''
  _LOG_CYAN=''
  _LOG_RESET=''
fi

_log_print() {
  local level="$1"
  local color="$2"
  shift 2
  printf '%b[%s] %s%b\n' "$color" "$level" "$*" "$_LOG_RESET"
}

info() { _log_print "INFO" "$_LOG_CYAN" "$@"; }
warn() { _log_print "WARN" "$_LOG_YELLOW" "$@"; }
error() { _log_print "ERROR" "$_LOG_RED" "$@" >&2; }
success() { _log_print "SUCCESS" "$_LOG_GREEN" "$@"; }
