#!/usr/bin/env bash

[[ -n "${__LIB_ENV_SH:-}" ]] && return 0
__LIB_ENV_SH=1

: "${ENV_VARS_FILE:=${PROJECT_ROOT:-$(pwd)}/.env}"

ensure_env_path() {
  case "$ENV_VARS_FILE" in
    /*) : ;;
    *) ENV_VARS_FILE="${PROJECT_ROOT:-$(pwd)}/$ENV_VARS_FILE" ;;
  esac
}

initialize_env_file() {
  ensure_env_path
  local env_dir
  env_dir=$(dirname "$ENV_VARS_FILE")

  mkdir -p "$env_dir" || {
    echo_error "Cannot create directory: $env_dir"
    return 1
  }

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
  ensure_env_path
  if [[ ! -f "$ENV_VARS_FILE" ]]; then
    echo_error "Environment file does not exist. Run initialization first."
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    echo_error "No variables provided"
    echo_info "Usage: save_env_var VAR1 VAR2 ..."
    return 1
  fi

  local updates=() tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"

  while [[ $# -gt 0 ]]; do
    local var_name="$1"
    shift
    local var_value
    eval "var_value=\${$var_name-}"
    if [[ -z "$var_value" ]]; then
      echo_error "Variable '$var_name' is empty or not set"
      rm -f "$tmp"
      return 1
    fi
    updates+=("$var_name")
  done

  while IFS= read -r line || [[ -n "$line" ]]; do
    local skip=false
    for v in "${updates[@]}"; do
      if [[ "$line" =~ ^export\ $v= ]]; then
        skip=true
        break
      fi
    done
    [[ "$skip" == true ]] || echo "$line" >> "$tmp"
  done < "$ENV_VARS_FILE"

  for v in "${updates[@]}"; do
    local val
    eval "val=\${$v}"
    echo "export $v=\"$val\"" >> "$tmp"
  done

  mv "$tmp" "$ENV_VARS_FILE"
  echo_success "Updated environment variables: ${updates[*]}"
}

list_env_vars() {
  ensure_env_path
  [[ -f "$ENV_VARS_FILE" ]] || { echo_info "No env file: $ENV_VARS_FILE"; return 0; }
  grep -E '^export [A-Za-z_][A-Za-z0-9_]*=' "$ENV_VARS_FILE" || true
}

get_env_var() {
  ensure_env_path
  local key="$1"
  [[ -f "$ENV_VARS_FILE" ]] || return 1
  awk -v key="$key" -F'=' '$1=="export "key {sub(/^"|"$/,"",$2); print $2; found=1} END{exit !found}' "$ENV_VARS_FILE"
}

unset_env_var() {
  ensure_env_path
  local key="$1"
  [[ -f "$ENV_VARS_FILE" ]] || { echo_error "No env file: $ENV_VARS_FILE"; return 1; }
  local tmp
  tmp=$(mktemp)
  chmod 600 "$tmp"
  grep -Ev "^export ${key}=" "$ENV_VARS_FILE" > "$tmp" || true
  mv "$tmp" "$ENV_VARS_FILE"
  echo_success "Removed variable: $key"
}
