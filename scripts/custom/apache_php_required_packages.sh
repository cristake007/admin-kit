#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
APACHE_PACKAGES=(apache2-doc php libapache2-mod-php libapache2-mod-xsendfile libapache2-mod-security2 apache2-utils libapache2-mod-evasive)
PHP_PACKAGES=(php8.2-cli php8.2-common php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-xml php8.2-zip php8.2-bz2 libapache2-mod-php8.2 php8.2-ldap php8.2-xmlrpc php8.2-soap php8.2-apcu php8.2-imagick php8.2-bcmath php8.2-gmp php8.2-igbinary php8.2-imap php8.2-redis php8.2-xsl php-pear)
APACHE_MODULES=(mime headers ssl rewrite alias proxy proxy_http proxy_wstunnel proxy_balancer lbmethod_byrequests proxy_http2 xml2enc socache_shmcb expires vhost_alias ldap authnz_ldap xsendfile security2 evasive)
check_installed(){ local p; for p in "${APACHE_PACKAGES[@]}" "${PHP_PACKAGES[@]}"; do apt_package_installed "$p" || return 1; done; return 0; }
check_conflicts(){ return 0; }
install_step(){ apt_update; apt_install "${APACHE_PACKAGES[@]}" "${PHP_PACKAGES[@]}"; local m; for m in "${APACHE_MODULES[@]}"; do sudo a2enmod "$m" >/dev/null 2>&1 || true; done; service_reload_or_restart apache2; wf_mark_changed "Installed Apache/PHP requirements and enabled modules"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line apache2; }
main(){ echo_info "This installs Apache/PHP packages for ILIAS requirements."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "apache_php_requirements" check_installed check_conflicts install_step summary_step; }
main "$@"
