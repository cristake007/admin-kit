#!/usr/bin/env bash
# scripts/helper/env_manager.sh
# Environment (.env) manager — standalone, matches your UI helpers

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

: "${ENV_VARS_FILE:="$SCRIPT_DIR/.env"}"

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
      if [[ -f "$ENV_VARS_FILE" ]]; then
        list_env_vars
      else
        echo_info "No env file yet. Choose option 1 to create it."
      fi
      pause
      ;;
    3)
      clear; display_header "Get a variable"
      read -r -p "Key: " k
      if [[ -z "$k" ]]; then echo_error "Key cannot be empty."; pause; continue; fi
      val="$(get_env_var "$k" || true)"
      if [[ -n "$val" ]]; then
        echo_success "$k=\"$val\""
      else
        echo_error "Variable not found: $k"
      fi
      pause
      ;;
    4)
      clear; display_header "Set/update variable(s)"
      if [[ ! -f "$ENV_VARS_FILE" ]]; then
        echo_info "No env file yet; creating…"
        initialize_env_file || { echo_error "Could not create $ENV_VARS_FILE"; pause; continue; }
      fi
      echo_info "Enter KEY=VALUE lines (blank line to finish)."
      echo_info "Examples: DOMAIN=example.com   DB_PASS='s3cr3t'"
      declare -a NAMES=()
      while IFS= read -r line; do
        [[ -z "$line" ]] && break
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
          key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
          export "$key=$val"
          NAMES+=("$key")
        else
          echo_error "Invalid format: $line"
        fi
      done
      if ((${#NAMES[@]})); then
        save_env_var "${NAMES[@]}" || echo_error "Failed to update one or more variables."
      else
        echo_info "No variables provided."
      fi
      pause
      ;;
    5)
      clear; display_header "Unset (delete) a variable"
      read -r -p "Key to remove: " k
      if [[ -z "$k" ]]; then echo_error "Key cannot be empty."; pause; continue; fi
      unset_env_var "$k"
      pause
      ;;
    6)
      clear; display_header "Edit .env"
      "${EDITOR:-${VISUAL:-nano}}" "$ENV_VARS_FILE"
      pause
      ;;
    0) exit 0 ;;
    *) echo_error "Invalid option. Please try again."; pause ;;
  esac
done
