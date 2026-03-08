#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

#===============================================================
# ENV FILE HANDLING
#===============================================================
# 1) Keep your default target
ENV_VARS_FILE="${ENV_VARS_FILE:-$PROJECT_ROOT/.env}"
# 2) Normalize to absolute path under PROJECT_ROOT if it's relative
case "$ENV_VARS_FILE" in
  /*) : ;;                   # already absolute
  *)  ENV_VARS_FILE="$PROJECT_ROOT/$ENV_VARS_FILE" ;;
esac

# (Optional) show where we're writing, handy for debugging

initialize_env_file() {
  local env_dir
  env_dir=$(dirname "$ENV_VARS_FILE")

  # Create directory if it doesn't exist
  if [[ ! -d "$env_dir" ]]; then
    mkdir -p "$env_dir" || {
      echo_error "Cannot create directory: $env_dir"
      return 1
    }
  fi

  # Create ENV_VARS_FILE if it doesn't exist
  if [[ ! -f "$ENV_VARS_FILE" ]]; then
    touch "$ENV_VARS_FILE" || {
      echo_error "Cannot create $ENV_VARS_FILE"
      return 1
    }
    chmod 600 "$ENV_VARS_FILE"
    echo_success "Created environment file: $ENV_VARS_FILE"
  else
    echo_info "Environment file already exists: $ENV_VARS_FILE"
  fi
}

save_env_var() {
  if [[ ! -f "$ENV_VARS_FILE" ]]; then
    echo_error "Environment file does not exist. Run initialization first."
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    echo_error "No variables provided"
    echo_info "Usage: save_env_var VAR1 VAR2 ..."
    return 1
  fi

  local updates=()
  local tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"

  while [[ $# -gt 0 ]]; do
    local var_name="$1"; shift
    local var_value
    eval "var_value=\${$var_name-}"

    if [[ -z "$var_value" ]]; then
      echo_error "Variable '$var_name' is empty or not set"
      rm -f "$tmp"
      return 1
    fi
    updates+=("$var_name")
  done

  # Copy existing file without old definitions of updated vars
  while IFS= read -r line || [[ -n "$line" ]]; do
    local skip=false
    for v in "${updates[@]}"; do
      if [[ "$line" =~ ^export\ $v= ]]; then
        skip=true; break
      fi
    done
    [[ "$skip" == true ]] || echo "$line" >> "$tmp"
  done < "$ENV_VARS_FILE"

  for v in "${updates[@]}"; do
    eval "val=\${$v}"
    echo "export $v=\"$val\"" >> "$tmp"
  done

  mv "$tmp" "$ENV_VARS_FILE"
  echo_success "Updated environment variables: ${updates[*]}"
}

main() {
  initialize_env_file
  # Example usage:
  # DB_PASS="secret"
  # save_env_var DB_PASS
}

main
