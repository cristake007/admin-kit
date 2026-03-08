#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/bootstrap.sh"
require_lib log
require_lib ui
require_lib core

readonly -A CATEGORY_TITLES=(
  [system]="System"
  [webserver]="Webserver"
  [databases]="Databases"
  [security]="Security"
  [developer]="Developer"
  [custom]="Custom"
)

readonly -a CATEGORY_ORDER=(
  system
  webserver
  databases
  security
  developer
  custom
)

# category|label|relative_script_path
readonly -a MENU_ACTIONS=(
  "system|Update system|scripts/system/update_system.sh"
  "system|Create privileged user|scripts/system/create_user.sh"
  "system|Set timezone|scripts/system/set_timezone.sh"
  "system|Set hostname|scripts/system/set_hostname.sh"
  "system|Install common packages|scripts/system/common_packages.sh"
  "webserver|Install Apache|scripts/webserver/apache2.sh"
  "webserver|Install Nginx|scripts/webserver/nginx.sh"
  "webserver|Install Certbot|scripts/webserver/certbot.sh"
  "databases|Install MariaDB|scripts/databases/install_mariadb.sh"
  "databases|Install MySQL|scripts/databases/install_mysql.sh"
  "databases|Install PostgreSQL|scripts/databases/install_postgresql.sh"
  "security|Disable SSH root login|scripts/security/ssh_disable_root.sh"
  "security|Install fail2ban|scripts/security/install_fail2ban.sh"
  "security|Install firewall tooling|scripts/security/install_ufw.sh"
  "developer|Install extrepo|scripts/developer/install_extrepo.sh"
  "developer|Install PHP|scripts/developer/install_php.sh"
  "developer|Install Composer|scripts/developer/install_composer.sh"
  "developer|Install Node.js|scripts/developer/install_nodejs.sh"
  "developer|Install Symfony prerequisites|scripts/developer/install_symfony.sh"
  "custom|ILIAS baseline workflow|scripts/custom/ilias.sh"
)

run_and_pause() {
  local rel_script="$1"
  if run_script "$rel_script"; then
    success "Done: $rel_script"
  else
    error "Failed: $rel_script"
  fi
  pause
}

collect_available_actions() {
  local category="$1"
  local -n out_actions="$2"
  local action_category=""
  local label=""
  local rel_script=""
  local full_path=""

  out_actions=()
  for action in "${MENU_ACTIONS[@]}"; do
    IFS='|' read -r action_category label rel_script <<<"$action"
    [[ "$action_category" == "$category" ]] || continue

    full_path="$PROJECT_ROOT/$rel_script"
    [[ -f "$full_path" ]] || continue

    if [[ ! -x "$full_path" ]]; then
      chmod +x "$full_path" 2>/dev/null || true
    fi

    [[ -x "$full_path" ]] || continue
    out_actions+=("$label|$rel_script")
  done
}

submenu() {
  local category="$1"
  local title="${CATEGORY_TITLES[$category]}"
  local -a actions=()
  local entry=""
  local label=""
  local rel_script=""
  local choice=""

  while true; do
    collect_available_actions "$category" actions

    clear
    display_header "$title"

    if [[ "${#actions[@]}" -eq 0 ]]; then
      warn "No implemented actions are currently available in this category."
      pause
      return
    fi

    local index=1
    for entry in "${actions[@]}"; do
      IFS='|' read -r label rel_script <<<"$entry"
      echo "$index) $label"
      index=$((index + 1))
    done
    echo "0) Back"

    read -r -p "Choice: " choice
    if [[ "$choice" == "0" ]]; then
      return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#actions[@]} )); then
      IFS='|' read -r label rel_script <<<"${actions[$((choice - 1))]}"
      run_and_pause "$rel_script"
      continue
    fi

    warn "Invalid option"
    pause
  done
}

collect_available_categories() {
  local -n out_categories="$1"
  local category=""
  local -a actions=()

  out_categories=()
  for category in "${CATEGORY_ORDER[@]}"; do
    collect_available_actions "$category" actions
    if [[ "${#actions[@]}" -gt 0 ]]; then
      out_categories+=("$category")
    fi
  done
}

main() {
  local -a categories=()
  local category=""
  local choice=""

  while true; do
    collect_available_categories categories

    clear
    display_header "Admin Kit"

    if [[ "${#categories[@]}" -eq 0 ]]; then
      error "No implemented menu actions are currently available."
      exit 1
    fi

    local index=1
    for category in "${categories[@]}"; do
      echo "$index) ${CATEGORY_TITLES[$category]}"
      index=$((index + 1))
    done
    echo "0) Exit"

    read -r -p "Choice: " choice
    if [[ "$choice" == "0" ]]; then
      exit 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#categories[@]} )); then
      submenu "${categories[$((choice - 1))]}"
      continue
    fi

    warn "Invalid option"
    pause
  done
}

main "$@"
