#!/usr/bin/env bash

[[ -n "${__LIB_VALIDATE_SH:-}" ]] && return 0
__LIB_VALIDATE_SH=1

validate_non_empty() {
  [[ -n "${1:-}" ]]
}

validate_username() {
  local username="$1"
  [[ "$username" =~ ^[a-z][-a-z0-9_]{0,31}$ ]]
}

validate_hostname_label() {
  local hn="$1"
  [[ "$hn" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]
}

validate_domain() {
  local dn="$1"
  [[ -z "$dn" || "$dn" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]
}

validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

validate_timezone() {
  local tz="$1"
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl list-timezones | grep -Fxq "$tz"
  else
    [[ "$tz" =~ ^[A-Za-z_]+/[A-Za-z0-9_+.-]+$ ]]
  fi
}


detect_server() {
  local has_apache=1 has_nginx=1
  if apt_package_installed apache2 || service_is_active apache2; then has_apache=0; fi
  if apt_package_installed nginx || service_is_active nginx; then has_nginx=0; fi

  if (( has_apache != 0 && has_nginx != 0 )); then
    echo_error "No supported webserver detected. Install Apache or Nginx first."
    return 1
  fi

  if (( has_apache == 0 && has_nginx == 0 )); then
    while true; do
      read -r -p "Use Certbot with which server? [a=Apache / n=Nginx]: " sel
      case "$sel" in
        a|A) SERVER="apache"; break ;;
        n|N) SERVER="nginx"; break ;;
        *) echo_error "Please choose 'a' or 'n'." ;;
      esac
    done
  elif (( has_apache == 0 )); then
    SERVER="apache"
  else
    SERVER="nginx"
  fi
}