#!/usr/bin/env bash
set -euo pipefail

# Self-bootstrap
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

detect_server() {
  local has_apache=1 has_nginx=1
  if command -v apache2ctl >/dev/null 2>&1 || systemctl is-active --quiet apache2 2>/dev/null; then has_apache=0; fi
  if command -v nginx      >/dev/null 2>&1 || systemctl is-active --quiet nginx   2>/dev/null; then has_nginx=0; fi

  if (( has_apache != 0 && has_nginx != 0 )); then
    echo_error "No supported webserver detected."
    echo_info  "Please install Apache or Nginx first."
    return 1
  fi

  if (( has_apache == 0 && has_nginx == 0 )); then
    echo_info "Both Apache and Nginx detected."
    while true; do
      echo -ne "${YELLOW}Use which server? [a) Apache / n) Nginx]: ${NC}"
      read -r sel
      case "$sel" in
        a|A) SERVER="apache"; break ;;
        n|N) SERVER="nginx";  break ;;
        *)   echo_error "Please choose 'a' or 'n'." ;;
      esac
    done
  elif (( has_apache == 0 )); then
    SERVER="apache"
  else
    SERVER="nginx"
  fi
  return 0
}

read_domain() {
  while true; do
    read -r -p "Enter domain (e.g., example.com): " DOMAIN
    DOMAIN="${DOMAIN,,}"; DOMAIN="${DOMAIN// /}"
    if [[ "$DOMAIN" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
      break
    else
      echo_error "Invalid domain. Use example.com or sub.example.org"
    fi
  done
  if confirm "Also include www.$DOMAIN as alias?"; then
    ADD_WWW=1
  else
    ADD_WWW=0
  fi
  WEBROOT="/var/www/$DOMAIN/public"
}

create_webroot() {
  echo_note "Creating web root at $WEBROOT ..."
  sudo mkdir -p "$WEBROOT"
  if [[ ! -f "$WEBROOT/index.html" ]]; then
    sudo tee "$WEBROOT/index.html" >/dev/null <<EOF
<!doctype html><meta charset="utf-8"><title>$DOMAIN</title>
<style>body{font-family:system-ui,Arial;margin:4rem} .badge{display:inline-block;padding:.3rem .6rem;border:1px solid #ccc;border-radius:.4rem}</style>
<h1>It works! 🎉</h1><p>Demo vhost for <strong>$DOMAIN</strong></p><p class="badge">$(date)</p>
EOF
  fi
  sudo chown -R www-data:www-data "/var/www/$DOMAIN"
}

configure_apache() {
  local conf="/etc/apache2/sites-available/${DOMAIN}.conf"
  if [[ -f "$conf" ]]; then
    if ! confirm "Apache vhost exists: ${conf}. Overwrite?"; then
      echo_info "Keeping existing vhost."; return 0
    fi
  fi

  echo_note "Writing Apache vhost: $conf"
  local server_alias=""
  [[ $ADD_WWW -eq 1 ]] && server_alias="ServerAlias www.$DOMAIN"

  sudo tee "$conf" >/dev/null <<APACHECONF
<VirtualHost *:80>
    ServerName $DOMAIN
    $server_alias
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
APACHECONF

  echo_note "Enabling site & mod_rewrite..."
  sudo a2enmod rewrite >/dev/null || true
  sudo a2ensite "${DOMAIN}.conf" >/dev/null

  echo_note "Testing Apache config..."
  sudo apache2ctl -t

  echo_note "Reloading Apache..."
  sudo systemctl reload apache2

  echo_success "Apache vhost for $DOMAIN is active."
}

configure_nginx() {
  local conf="/etc/nginx/sites-available/${DOMAIN}"
  local link="/etc/nginx/sites-enabled/${DOMAIN}"
  if [[ -f "$conf" ]]; then
    if ! confirm "Nginx server block exists: ${conf}. Overwrite?"; then
      echo_info "Keeping existing server block."; return 0
    fi
  fi

  echo_note "Writing Nginx server block: $conf"
  local names="$DOMAIN"
  [[ $ADD_WWW -eq 1 ]] && names="$names www.$DOMAIN"

  sudo tee "$conf" >/dev/null <<NGINXCONF
server {
    listen 80;
    listen [::]:80;

    server_name $names;
    root $WEBROOT;
    index index.html index.htm;

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log  /var/log/nginx/${DOMAIN}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINXCONF

  echo_note "Enabling site..."
  sudo ln -sf "$conf" "$link"

  echo_note "Testing Nginx config..."
  sudo nginx -t

  echo_note "Reloading Nginx..."
  sudo systemctl reload nginx

  echo_success "Nginx server block for $DOMAIN is active."
}

main() {
  detect_server || exit 1
  echo_info "Using server: $SERVER"

  read_domain
  create_webroot

  if [[ "$SERVER" == "apache" ]]; then
    configure_apache
  else
    configure_nginx
  fi

  echo_success "Demo vhost ready at: http://$DOMAIN/"
  [[ $ADD_WWW -eq 1 ]] && echo_info "Also: http://www.$DOMAIN/"
}

main
