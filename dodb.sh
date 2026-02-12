#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require "functions/functions.sh"

trap 'err_trap' ERR
need_sudo || exit 1

validate_db_identifier() {
  local value="$1"
  [[ "$value" =~ ^[A-Za-z0-9_]+$ ]]
}

read_password_twice() {
  local pass1 pass2
  while true; do
    read -r -s -p "Enter password for DB user: " pass1
    echo
    read -r -s -p "Confirm password: " pass2
    echo

    if [[ -z "$pass1" ]]; then
      echo_error "Password cannot be empty."
      continue
    fi

    if [[ "$pass1" != "$pass2" ]]; then
      echo_error "Passwords do not match. Please try again."
      continue
    fi

    DB_PASS="$pass1"
    return 0
  done
}

mysql_like_create_db_user() {
  local engine="$1"
  local db_name="$2"
  local db_user="$3"
  local db_pass="$4"

  local sql
  sql=$(cat <<SQL
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
SQL
)

  if [[ "$engine" == "mysql" ]]; then
    sudo mysql -e "$sql"
  else
    sudo mariadb -e "$sql"
  fi
}

postgres_create_db_user() {
  local db_name="$1"
  local db_user="$2"
  local db_pass="$3"

  sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${db_user}') THEN
    CREATE ROLE "${db_user}" LOGIN PASSWORD '${db_pass}';
  END IF;
END
\$\$;
SQL

  if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${db_name}'" | grep -q 1; then
    sudo -u postgres createdb -O "$db_user" "$db_name"
  fi

  sudo -u postgres psql -d "$db_name" -c "GRANT ALL PRIVILEGES ON DATABASE \"${db_name}\" TO \"${db_user}\";"
}

main() {
  clear
  display_header "Database/User Quick Setup (dodb.sh)"

  local engine_choice db_engine
  echo_note "1) MySQL"
  echo_note "2) MariaDB"
  echo_note "3) PostgreSQL"
  echo_note "0) Exit"
  echo -ne "\n${YELLOW}Choose database engine:${NC} "
  read -r engine_choice

  case "$engine_choice" in
    1) db_engine="mysql" ;;
    2) db_engine="mariadb" ;;
    3) db_engine="postgresql" ;;
    0) echo_info "Cancelled."; exit 0 ;;
    *) echo_error "Invalid option."; exit 1 ;;
  esac

  read -r -p "Database name (letters, numbers, underscore): " DB_NAME
  read -r -p "Database user (letters, numbers, underscore): " DB_USER

  if ! validate_db_identifier "$DB_NAME"; then
    echo_error "Invalid database name: use only letters, numbers, underscore."
    exit 1
  fi

  if ! validate_db_identifier "$DB_USER"; then
    echo_error "Invalid user name: use only letters, numbers, underscore."
    exit 1
  fi

  read_password_twice

  echo_info "Preparing to create database and user for ${db_engine}."
  echo_note "Database: $DB_NAME"
  echo_note "User: $DB_USER"

  if ! confirm "Continue?"; then
    echo_info "Cancelled."
    exit 0
  fi

  case "$db_engine" in
    mysql)
      command_exists mysql || { echo_error "MySQL client not found. Install MySQL first."; exit 1; }
      mysql_like_create_db_user "$db_engine" "$DB_NAME" "$DB_USER" "$DB_PASS"
      ;;
    mariadb)
      command_exists mariadb || { echo_error "MariaDB client not found. Install MariaDB first."; exit 1; }
      mysql_like_create_db_user "$db_engine" "$DB_NAME" "$DB_USER" "$DB_PASS"
      ;;
    postgresql)
      command_exists psql || { echo_error "psql not found. Install PostgreSQL first."; exit 1; }
      postgres_create_db_user "$DB_NAME" "$DB_USER" "$DB_PASS"
      ;;
  esac

  echo_success "Done. Database and user are ready."
}

main "$@"
