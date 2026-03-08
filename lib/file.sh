#!/usr/bin/env bash

[[ -n "${__LIB_FILE_SH:-}" ]] && return 0
__LIB_FILE_SH=1

backup_file() {
  local src_file="$1"
  local backup_dir="$2"
  mkdir -p "$backup_dir"
  if [[ -f "$src_file" ]]; then
    cp "$src_file" "$backup_dir"
    echo_info "Backup of $src_file created in $backup_dir"
  fi
}

verify_creation() {
  local file_path="$1"
  local description="$2"
  if [[ -f "$file_path" ]]; then
    echo_success "$description created successfully at $file_path"
  else
    echo_error "$description was not created at $file_path"
    return 1
  fi
}

directory_has_content() {
  local dir="$1"
  [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir")" ]]
}

ensure_directory() {
  local dir="$1"
  local description="$2"
  local owner="${3:-}"
  local mode="${4:-}"

  mkdir -p "$dir" || {
    echo_error "Failed to create directory: $description ($dir)"
    return 1
  }

  if [[ -n "$owner" ]]; then
    sudo chown -R "$owner" "$dir"
  fi
  if [[ -n "$mode" ]]; then
    sudo chmod -R "$mode" "$dir"
  fi

  echo_success "Ready: $description ($dir)"
}

clean_and_create_directory() {
  local dir="$1"
  local description="$2"

  if [[ -d "$dir" ]] && directory_has_content "$dir"; then
    echo_info "Directory exists and has content: $description ($dir)"
    sudo chown -R www-data:www-data "$dir"
    sudo chmod -R 775 "$dir"
    return 0
  fi

  ensure_directory "$dir" "$description" "www-data:www-data" "775"
}

clean_and_create_backup_directory() {
  local dir="$1"
  local description="$2"

  if [[ -d "$dir" ]] && directory_has_content "$dir"; then
    echo_info "Directory exists and has content: $description ($dir)"
    return 0
  fi

  ensure_directory "$dir" "$description"
}
