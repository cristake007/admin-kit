#!/usr/bin/env bash

[[ -n "${__LIB_LOG_SH:-}" ]] && return 0
__LIB_LOG_SH=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

_print() { echo -e "${2}${1}${NC}"; }
echo_success() { _print "$1" "$GREEN"; }
echo_error() { _print "$1" "$RED"; }
echo_info() { _print "$1" "$YELLOW"; }
echo_note() { _print "$1" "$CYAN"; }
