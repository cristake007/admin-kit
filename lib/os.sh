#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_OS_SH:-}" ]] && return 0
__LIB_OS_SH=1

OS_ID=""
OS_ID_LIKE=""
OS_FAMILY="unsupported"
PKG_BACKEND=""
SERVICE_BACKEND="unknown"
FIREWALL_BACKEND="unknown"

os_detect() {
  if [[ ! -r /etc/os-release ]]; then
    OS_FAMILY="unsupported"
    return 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_ID_LIKE="${ID_LIKE:-}"

  local marker="${OS_ID} ${OS_ID_LIKE}"
  case "$marker" in
    *debian*|*ubuntu*)
      OS_FAMILY="debian"
      PKG_BACKEND="apt"
      FIREWALL_BACKEND="ufw"
      ;;
    *rhel*|*fedora*|*rocky*|*almalinux*|*centos*)
      OS_FAMILY="rhel"
      FIREWALL_BACKEND="firewalld"
      if command -v dnf >/dev/null 2>&1; then
        PKG_BACKEND="dnf"
      elif command -v yum >/dev/null 2>&1; then
        PKG_BACKEND="yum"
      else
        PKG_BACKEND=""
      fi
      ;;
    *suse*|*opensuse*)
      OS_FAMILY="suse"
      PKG_BACKEND="zypper"
      FIREWALL_BACKEND="firewalld"
      ;;
    *arch*)
      OS_FAMILY="arch"
      PKG_BACKEND="pacman"
      FIREWALL_BACKEND="firewalld"
      ;;
    *)
      OS_FAMILY="unsupported"
      PKG_BACKEND=""
      FIREWALL_BACKEND="unknown"
      ;;
  esac

  if command -v systemctl >/dev/null 2>&1; then
    SERVICE_BACKEND="systemd"
  fi
}

os_require_supported() {
  if [[ "$OS_FAMILY" == "unsupported" || -z "$PKG_BACKEND" ]]; then
    error "Unsupported Linux distribution: ID=${OS_ID:-unknown} ID_LIKE=${OS_ID_LIKE:-none}."
    return 1
  fi
}

os_family() {
  printf '%s\n' "$OS_FAMILY"
}

os_resolve_pkg() {
  local capability="${1:?capability required}"

  case "$capability" in
    apache_server)
      [[ "$OS_FAMILY" == "debian" ]] && printf 'apache2\n' || printf 'httpd\n'
      ;;
    mariadb_server)
      [[ "$OS_FAMILY" == "arch" ]] && printf 'mariadb\n' || printf 'mariadb-server\n'
      ;;
    mysql_server)
      case "$OS_FAMILY" in
        debian) printf 'default-mysql-server\n' ;;
        rhel|suse) printf 'mysql-server\n' ;;
        *) return 1 ;;
      esac
      ;;
    postgresql_server)
      printf 'postgresql\n'
      ;;
    firewall_tool)
      if [[ "$FIREWALL_BACKEND" == "ufw" ]]; then
        printf 'ufw\n'
      elif [[ "$FIREWALL_BACKEND" == "firewalld" ]]; then
        printf 'firewalld\n'
      else
        return 1
      fi
      ;;
    php_runtime_bundle)
      case "$OS_FAMILY" in
        debian) printf 'php php-cli php-mysql php-xml php-mbstring php-zip php-curl\n' ;;
        rhel) printf 'php php-cli php-mysqlnd php-xml php-mbstring php-zip php-curl\n' ;;
        suse) printf 'php8 php8-cli php8-mysql php8-xmlreader php8-mbstring php8-zip php8-curl\n' ;;
        arch) printf 'php php-apache\n' ;;
        *) return 1 ;;
      esac
      ;;
    *)
      error "Unknown package capability: $capability"
      return 1
      ;;
  esac
}

os_resolve_service() {
  local capability="${1:?capability required}"

  case "$capability" in
    apache)
      [[ "$OS_FAMILY" == "debian" ]] && printf 'apache2\n' || printf 'httpd\n'
      ;;
    mysql)
      [[ "$OS_FAMILY" == "debian" ]] && printf 'mysql\n' || printf 'mysqld\n'
      ;;
    mariadb)
      printf 'mariadb\n'
      ;;
    postgresql)
      printf 'postgresql\n'
      ;;
    firewall)
      [[ "$FIREWALL_BACKEND" == "firewalld" ]] && printf 'firewalld\n' || return 1
      ;;
    *)
      error "Unknown service capability: $capability"
      return 1
      ;;
  esac
}
