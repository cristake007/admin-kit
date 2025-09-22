#!/usr/bin/env bash


[[ -n "${__FUNCTIONS_SH:-}" ]] && return 0
__FUNCTIONS_SH=1

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# Logging
_print(){ echo -e "${2}${1}${NC}"; }
echo_success(){ _print "$1" "$GREEN"; }
echo_error()  { _print "$1" "$RED"; }
echo_info()   { _print "$1" "$YELLOW"; }
echo_note()   { _print "$1" "$CYAN"; }


# Pause for user input
pause(){ echo_info "Press Enter to continue..."; read -r; }


# Display a header with system info
display_header() {
    local text="$1"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))

    printf "\n%${padding}s${GREEN}%s${NC}%${padding}s\n\n" "" "$text" ""
    echo_info "Hostname: $(hostname)"
    echo_info "Kernel: $(uname -r)"
    echo_info "Uptime: $(uptime -p)"
    echo_info "Last Boot: $(who -b | awk '{print $3,$4}')"
    echo_info "CPU Model: $(lscpu | grep "Model name" | sed 's/Model name://' | xargs)"
    echo_info "CPU Cores: Physical: $(grep -c ^processor /proc/cpuinfo), Logical: $(nproc)"
    printf "%$(tput cols)s\n" | tr ' ' '-'
}

# Robust script runner with logging and error handling
run() {
  local target="$1"; shift || true
  if [[ ! -f "$target" ]]; then
    echo_error "Script not found: $target"
    return 127
  fi

  # optional per-run log
  local log="/tmp/$(basename "$target").$(date +%s).log"

  # show output live, capture real exit via PIPESTATUS
  if ! bash "$target" "$@" 2>&1 | tee "$log"; then
    local rc=${PIPESTATUS[0]}
    echo_error "$(basename "$target") failed (exit $rc). Log: $log"
    return "$rc"
  fi
}

# nice-to-have: fatal wrapper when you *do* want to abort
run_fatal() {
  run "$@" || { echo_error "Fatal: $(basename "$1") failed."; exit 1; }
}

# optional shared error trap handler (only used if scripts set `trap`)
err_trap(){ echo_error "Error (rc=$?) while running: ${BASH_COMMAND}"; }

# yes/no prompt
confirm(){ read -r -p "${1:-Proceed?} (y/n): " ans; [[ "$ans" =~ ^[Yy]$ ]]; }

# ensure script is run with sudo privileges
need_sudo(){
  if [[ $EUID -ne 0 ]]; then
    echo_info "Elevating privileges with sudo..."
    sudo -v || { echo_error "sudo failed."; return 1; }
  fi
}

# Convenience: install multiple packages (Debian)
install_items(){
  local kind="${1:-package}"; shift || true
  if [[ $# -eq 0 ]]; then echo_error "No ${kind}s specified."; return 1; fi
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

# MySQL repo setup (Debian)
add_mysql_repo() {
  echo_note "Adding Oracle MySQL APT repository (8.4 LTS)..."
  curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | sudo gpg --dearmor -o "$MYSQL_KEYRING"
  echo "deb [signed-by=$MYSQL_KEYRING] http://repo.mysql.com/apt/debian/ bookworm mysql-8.4-lts mysql-tools" \
    | sudo tee "$MYSQL_LIST" >/dev/null
}

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

# Apt helpers (Debian/Ubuntu)
export DEBIAN_FRONTEND=noninteractive

apt_update(){ sudo apt-get update -y; }

apt_upgrade(){
  sudo apt-get -o Dpkg::Options::="--force-confdef" \
               -o Dpkg::Options::="--force-confold" \
               dist-upgrade -y
}

apt_install(){ sudo apt-get install -y "$@"; }

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


apt_remove(){ sudo apt-get remove -y "$@"; }

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


confirm_skip() {
  local prompt="${1:-Proceed?}"
  local ans
  while true; do
    read -r -p "${prompt} (y=yes / n=no / s=skip): " ans
    case "$ans" in
      [Yy]) return 0 ;;
      [Nn]) return 1 ;;
      [Ss]) return 2 ;;
      *) echo_error "Please enter y, n, or s." ;;
    esac
  done
}




#===============================================================
# VARBIABLE FILE FUNCTIONS, IT SAVES THE INFORMATION TO BE 
# PASSED TO OTHER SCRIPTS - EX: DB PASS, USERNAME AND SO ON
#===============================================================

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
        echo_log "Environment file initialized: $ENV_VARS_FILE"
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
    echo_log "Updated environment variables: ${updates[*]}"
    return 0
}


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