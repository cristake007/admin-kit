#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/env.sh"
trap err_trap ERR

: "${ENV_VARS_FILE:=$PROJECT_ROOT/.env}"

while true; do
  clear
  display_header "Environment (.env) manager"
  echo_note "File: $ENV_VARS_FILE"
  echo_note ""
  echo_note "1) Initialize .env (create if missing)"
  echo_note "2) List variables"
  echo_note "3) Get a variable"
  echo_note "4) Set/update variable(s)"
  echo_note "5) Unset (delete) a variable"
  echo_note "6) Edit .env in \$EDITOR"
  echo_note "0) Return to previous menu"
  echo -ne "\n${YELLOW}Enter your choice:${NC} "
  read -r choice

  case "$choice" in
    1)
      clear; display_header "Initialize .env"
      initialize_env_file || echo_error "Initialization failed."
      pause
      ;;
    2)
      clear; display_header "List variables"
      list_env_vars
      pause
      ;;
    3)
      clear; display_header "Get a variable"
      read -r -p "Key: " k
      if [[ -z "$k" ]]; then
        echo_error "Key cannot be empty."
      else
        val="$(get_env_var "$k" || true)"
        [[ -n "$val" ]] && echo_success "$k=\"$val\"" || echo_error "Variable not found: $k"
      fi
      pause
      ;;
    4)
      clear; display_header "Set/update variable(s)"
      initialize_env_file || { echo_error "Could not create $ENV_VARS_FILE"; pause; continue; }
      echo_info "Enter KEY=VALUE lines (blank line to finish)."
      declare -a names=()
      while IFS= read -r line; do
        [[ -z "$line" ]] && break
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
          key="${BASH_REMATCH[1]}"
          val="${BASH_REMATCH[2]}"
          export "$key=$val"
          names+=("$key")
        else
          echo_error "Invalid format: $line"
        fi
      done
      ((${#names[@]})) && save_env_var "${names[@]}" || echo_info "No variables provided."
      pause
      ;;
    5)
      clear; display_header "Unset (delete) a variable"
      read -r -p "Key to remove: " k
      [[ -z "$k" ]] && echo_error "Key cannot be empty." || unset_env_var "$k"
      pause
      ;;
    6)
      clear; display_header "Edit .env"
      initialize_env_file || true
      "${EDITOR:-${VISUAL:-nano}}" "$ENV_VARS_FILE"
      pause
      ;;
    0) exit 0 ;;
    *) echo_error "Invalid option. Please try again."; pause ;;
  esac
done
