#!/usr/bin/env bash

#======================================================================
#  functions.sh
#  Purpose:
#    Shared utility functions for logging, prompts, APT helpers,
#    environment variable persistence, and common admin helpers.
#  Notes:
#    - Logic inside functions is unchanged.
#    - Only ordering and section headers were added for clarity.
#======================================================================

[[ -n "${__FUNCTIONS_SH:-}" ]] && return 0
__FUNCTIONS_SH=1

#======================================================================
# SECTION 1: Colors & Logging
# - Color constants
# - Basic logging helpers: success, error, info, note
#======================================================================

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# Logging
_print(){ echo -e "${2}${1}${NC}"; }
echo_success(){ _print "$1" "$GREEN"; }
echo_error()  { _print "$1" "$RED"; }
echo_info()   { _print "$1" "$YELLOW"; }
echo_note()   { _print "$1" "$CYAN"; }

#======================================================================
# SECTION 2: UX Utilities
# - pause: press-Enter pause
# - display_header: terminal banner and quick system facts
#======================================================================

# Pause for user input
pause(){ echo_info "Press Enter to continue..."; read -r; }

terminal_width() {
  local width="${COLUMNS:-0}"
  if [[ "$width" -le 0 ]]; then
    if command -v tput >/dev/null 2>&1; then
      width="$(tput cols 2>/dev/null || echo 0)"
    fi
  fi
  [[ "$width" =~ ^[0-9]+$ ]] || width=0
  if [[ "$width" -le 0 ]]; then
    width=80
  fi
  printf '%s\n' "$width"
}

# Display a header with system info
display_header() {
    local text="$1"
    local width
    width="$(terminal_width)"
    local padding=$(( (width - ${#text}) / 2 ))

    printf "\n%${padding}s${GREEN}%s${NC}%${padding}s\n\n" "" "$text" ""
    echo_info "Hostname: $(hostname)"
    echo_info "Kernel: $(uname -r)"
    echo_info "Uptime: $(uptime -p)"
    echo_info "Last Boot: $(who -b | awk '{print $3,$4}')"
    echo_info "CPU Model: $(lscpu | grep "Model name" | sed 's/Model name://' | xargs)"
    echo_info "CPU Cores: Physical: $(grep -c ^processor /proc/cpuinfo), Logical: $(nproc)"
    printf "%${width}s\n" | tr ' ' '-'
}

show_script_metadata() {
  local requires="${1:-N/A}"
  local privileges="${2:-N/A}"
  local distro="${3:-N/A}"
  local side_effects="${4:-N/A}"
  local rerun_safe="${5:-N/A}"

  echo_note "Requirements: ${requires}"
  echo_note "Privileges: ${privileges}"
  echo_note "Target distro: ${distro}"
  echo_note "Side effects: ${side_effects}"
  echo_note "Safe to re-run: ${rerun_safe}"
}

#======================================================================
# SECTION 3: Execution Wrappers & Error Trap
# - run: execute a script with live logging to a temp file
# - run_fatal: wrapper that exits on failure
# - err_trap: generic error trap hook
#======================================================================

# Robust script runner with logging and error handling
run() {
  local target="$1"; shift || true
  local caller_src="${BASH_SOURCE[1]:-unknown}"
  local caller_line="${BASH_LINENO[0]:-?}"

  if [[ ! -f "$target" ]]; then
    echo_error "Script not found: $target"
    echo_error "Called from ${caller_src}:${caller_line}"
    return 127
  fi

  local log="/tmp/$(basename "$target").$(date +%s).log"

  # Keep stdin attached to tty for interactive scripts
  if ! bash "$target" "$@" \
      > >(tee "$log") \
      2> >(tee -a "$log" >&2); then
    local rc=$?
    echo_error "$(basename "$target") failed (exit $rc)"
    echo_error "Called from ${caller_src}:${caller_line}"
    echo_error "Log: $log"
    tail -n 30 "$log" | sed 's/^/  /'
    return "$rc"
  fi
}

# nice-to-have: fatal wrapper when you *do* want to abort
run_fatal() {
  run "$@" || { echo_error "Fatal: $(basename "$1") failed."; exit 1; }
}

# optional shared error trap handler (only used if scripts set `trap`)
err_trap() {
  local rc=$?
  local cmd=${BASH_COMMAND:-?}
  local src=${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}
  local line=${BASH_LINENO[0]:-?}
  local func=${FUNCNAME[1]:-MAIN}

  echo_error "ERROR: rc=$rc at ${src}:${line} in ${func}()"
  echo_error "Command: $cmd"

  # mini stack trace
  local i
  for ((i=1; i<${#FUNCNAME[@]}; i++)); do
    echo_error "  at ${BASH_SOURCE[$i]}:${BASH_LINENO[$((i-1))]} ${FUNCNAME[$i]}()"
  done

  # don't exit here; let caller decide (menu may want to continue)
  return "$rc"
}

#======================================================================
# SECTION 4: Prompts & Confirmation
# - confirm: (Y/n) prompt with Enter defaulting to Yes
# - confirm_skip: y/n/s prompt for skip-aware flows
#======================================================================

# yes/no prompt
confirm() {
    read -r -p "${1:-Proceed?} (Y/n): " ans
    echo
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

confirm_skip() {
  local prompt="${1:-Proceed?}"
  local ans
  while true; do
    read -r -p "${prompt} (y=yes / n=no / s=skip): " ans
    echo
    case "$ans" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      [Ss]) return 2 ;;
      *) echo_error "Please enter y, n, or s." ;;
    esac
  done
}

#======================================================================
# SECTION 5: Privilege & User Checks
# - need_sudo: ensure sudo timestamp is valid
# - has_sudo_user: detect a non-root sudo-capable user
#======================================================================

# ensure script is run with sudo privileges
need_sudo(){
  if [[ $EUID -eq 0 ]]; then
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo_error "sudo is required for this script when not running as root."
    return 1
  fi

  if [[ $EUID -ne 0 ]]; then
    echo_info "Elevating privileges with sudo..."
    sudo -v || { echo_error "sudo failed."; return 1; }
  fi
}

run_privileged() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
    return
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo_error "sudo is required for privileged command: $*"
    return 1
  fi

  sudo "$@"
}

# Returns 0 if there's at least one non-root user (uid >= 1000) in sudo or wheel
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

#======================================================================
# SECTION 6: System/Service/User Existence Checks
# - command_exists: is a command on PATH?
# - service_is_active: is a systemd service active?
# - user_exists: does a user exist?
#======================================================================

#check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

#check if a service is active
service_is_active() {
  systemctl is-active --quiet "$1" 2>/dev/null
}

#check if a user exists
user_exists() {
  id -u "$1" >/dev/null 2>&1
}

#======================================================================
# SECTION 7: APT Helpers (Debian/Ubuntu)
# - apt_update / apt_upgrade / apt_install / apt_remove
# - apt_is_installed: smarter detector for packages/binaries
# - install_items: batch install with apt-get
# - add_mysql_repo: Oracle MySQL 8.4 LTS repo setup (Bookworm)
#======================================================================

# Apt helpers (Debian/Ubuntu)
export DEBIAN_FRONTEND=noninteractive

apt_update(){ run_privileged apt-get update -y; }

apt_upgrade(){
  run_privileged apt-get -o Dpkg::Options::="--force-confdef" \
                         -o Dpkg::Options::="--force-confold" \
                         dist-upgrade -y
}

apt_install(){ run_privileged apt-get install -y "$@"; }

apt_remove(){ run_privileged apt-get remove -y "$@"; }

# Convenience: install multiple packages (Debian)
install_items(){
  local kind="${1:-package}"; shift || true
  if [[ $# -eq 0 ]]; then echo_error "No ${kind}s specified."; return 1; fi
  run_privileged apt-get update -y
  run_privileged env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# Smarter package/binary detector
apt_is_installed() {
  local name="$1"

  # 1. Check dpkg (APT-managed packages)
  if dpkg -s "$name" >/dev/null 2>&1; then
    return 0
  fi

  # 2. Check if a matching command is on PATH (binary or manual install)
  if command -v "$name" >/dev/null 2>&1; then
    return 0
  fi

  # 2b. Special case: some packages install a binary under /usr/local/bin
  if [[ -x "/usr/local/bin/$name" ]]; then
    return 0
  fi

  # 3. Check systemd services (sometimes package name differs)
  if systemctl list-unit-files 2>/dev/null | grep -q "^${name}.service"; then
    return 0
  fi

  # 4. Check snap packages
  if command -v snap >/dev/null 2>&1; then
    if snap list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$name"; then
      return 0
    fi
  fi

  # 5. Check flatpak packages
  if command -v flatpak >/dev/null 2>&1; then
    if flatpak list 2>/dev/null | awk -F'\t' '{print $1}' | grep -qx "$name"; then
      return 0
    fi
  fi

  return 1
}

# MySQL repo setup (Debian)
add_mysql_repo() {
  echo_note "Adding Oracle MySQL APT repository (8.4 LTS)..."
  curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | run_privileged gpg --dearmor -o "$MYSQL_KEYRING"
  echo "deb [signed-by=$MYSQL_KEYRING] http://repo.mysql.com/apt/debian/ bookworm mysql-8.4-lts mysql-tools" \
    | run_privileged tee "$MYSQL_LIST" >/dev/null
}

#======================================================================
# SECTION 8: Environment Variables Persistence
# - initialize_env_file: create protected .env file if missing
# - save_env_var: persist selected exported variables into .env
#======================================================================

# Define the path to the environment variables script
export ENV_VARS_FILE=".env"

# Initialize the environment file - call this ONCE in init.sh
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
      echo_note "Environment file initialized: $ENV_VARS_FILE"
  else
      echo_info "Environment file already exists: $ENV_VARS_FILE"
  fi
}

# Save or update environment variables - use this in subsequent scripts
save_env_var() {
  # Check if env file exists
  if [[ ! -f "$ENV_VARS_FILE" ]]; then
      echo_error "Environment file does not exist. Run initialization first."
      return 1
  fi

  # Check if no arguments were provided
  if [[ $# -eq 0 ]]; then
      echo_error "No variables provided to save_env_var function"
      echo_info "Usage: save_env_var VARIABLE_NAME [VARIABLE_NAME2 ...]"
      return 1
  fi

  local updates=()
  local temp_file
  temp_file=$(mktemp)
  chmod 600 "$temp_file"

  # Process each variable
  while [[ $# -gt 0 ]]; do
      local var_name="$1"
      shift

      # Get variable value
      local var_value
      eval "var_value=\${$var_name-}"

      if [[ -z "$var_value" ]]; then
          echo_error "Variable '$var_name' is empty or not set"
          rm -f "$temp_file"
          return 1
      fi

      updates+=("$var_name")
  done

  # Copy existing content, excluding variables we're updating
  while IFS= read -r line || [[ -n "$line" ]]; do
      local skip=false
      for var in "${updates[@]}"; do
          if [[ "$line" =~ ^export\ $var= ]]; then
              skip=true
              break
          fi
      done
      if [[ "$skip" == true ]]; then
          continue
      fi
      echo "$line" >> "$temp_file"
  done < "$ENV_VARS_FILE"

  # Add new/update existing variables
  for var in "${updates[@]}"; do
      eval "value=\${$var}"
      echo "export $var=\"$value\"" >> "$temp_file"
  done

  # Replace original file
  mv "$temp_file" "$ENV_VARS_FILE"
  
  echo_success "Updated environment variables: ${updates[*]}"
  echo_note "Updated environment variables: ${updates[*]}"
  return 0
}

#======================================================================
# SECTION 9: Filesystem Utilities
# - backup_file: simple file backup to a directory
# - verify_creation: assert a file was created
# - directory_has_content: quick check for non-empty directories
# - clean_and_create_directory: ensure web dir exists + perms
# - clean_and_create_backup_directory: ensure backup dir exists
#======================================================================

# backup_file function: Back up existing configuration file
backup_file() {
  local src_file="$1"
  local backup_dir="$2"
  mkdir -p "$backup_dir"
  if [[ -f "$src_file" ]]; then
      cp "$src_file" "$backup_dir"
      echo "Backup of $src_file created in $backup_dir"
  fi
}

# verify_creation function: Confirm file creation
verify_creation() {
  local file_path="$1"
  local description="$2"
  if [[ -f "$file_path" ]]; then
      echo "$description created successfully at $file_path"
  else
      echo "Error: $description was not created at $file_path"
      exit 1
  fi
}

# Function to check if directory has content
directory_has_content() {
  local dir="$1"
  [ -d "$dir" ] && [ "$(ls -A "$dir")" ]
}

# Function to clean and create directory
clean_and_create_directory() {
  local dir="$1"
  local description="$2"
  
  # Check if directory exists
  if [ -d "$dir" ]; then
      # Check if directory has content
      if directory_has_content "$dir"; then
          echo_info "Directory exists and has content: $description ($dir)"
          # Set proper permissions without deleting
          chown -R www-data:www-data "$dir"
          chmod -R 775 "$dir"
          return 0
      fi
  fi

  # Create directory if it doesn't exist or was empty
  mkdir -p "$dir" 2>/dev/null
  if [ $? -eq 0 ]; then
      echo_success "Created directory: $description ($dir)"
      # Set proper permissions
      chown -R www-data:www-data "$dir"
      chmod -R 775 "$dir"
      return 0
  else
      echo_error "Failed to create directory: $description ($dir)"
      return 1
  fi
}

# Function to clean and create directory
clean_and_create_backup_directory() {
  local dir="$1"
  local description="$2"
  
  # Check if directory exists
  if [ -d "$dir" ]; then
      # Check if directory has content
      if directory_has_content "$dir"; then
          echo_info "Directory exists and has content: $description ($dir)"
          # Set proper permissions without deleting
          # chown -R www-data:www-data "$dir"
          # chmod -R 775 "$dir"
          return 0
      fi
  fi

  # Create directory if it doesn't exist or was empty
  mkdir -p "$dir" 2>/dev/null
  if [ $? -eq 0 ]; then
      echo_success "Created directory: $description ($dir)"
      # Set proper permissions
      # chown -R www-data:www-data "$dir"
      # chmod -R 775 "$dir"
      return 0
  else
      echo_error "Failed to create directory: $description ($dir)"
      return 1
  fi
}
