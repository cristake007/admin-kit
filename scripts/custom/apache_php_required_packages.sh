#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main(){
#===========================================
# APACHE INSTALLATION AND CONFIGURATION
#===========================================
    install_and_configure_apache() {
        local retval=0

        local APACHE_PACKAGES=(
            "apache2-doc" "php" "libapache2-mod-php"
            "libapache2-mod-xsendfile" "libapache2-mod-security2"
            "apache2-utils" "libapache2-mod-evasive"
        )

        local APACHE_MODULES=(
            "mime" "headers" "ssl" "rewrite" "alias" "proxy"
            "proxy_http" "proxy_wstunnel" "proxy_balancer"
            "lbmethod_byrequests" "proxy_http2" "xml2enc"
            "socache_shmcb" "expires"
            "vhost_alias" "ldap" "authnz_ldap" "xsendfile"
            "security2" "evasive"
        )

        echo_info "Installing Apache-related packages."
        if ! env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APACHE_PACKAGES[@]}"; then
            echo_error "Failed to install Apache packages"
            return 1
        fi
        echo_success "Apache-related system packages installed."

        echo_info "Enabling Apache modules."
        for module in "${APACHE_MODULES[@]}"; do
            if ! a2enmod "$module" > >(grep -E 'warning|error') 2>&1; then
                echo_error "Failed to enable module '$module'."
                retval=1
            fi
            echo_info "Module '$module' enabled successfully."
        done

        if [ $retval -eq 0 ]; then
            echo_success "Apache modules enabled successfully."
        else
            echo_error "Failed to enable all Apache modules."
        fi

        return $retval
    }

    install_and_configure_apache





    #===========================================
    # PHP 8.2 INSTALLATION
    #===========================================
    # Install PHP 8.2 and required extensions
    install_php82() {
        echo_info "Installing PHP packages."
        PHP_PACKAGES=(
            "php8.2-cli" "php8.2-common" "php8.2-curl"
            "php8.2-gd" "php8.2-intl" "php8.2-mbstring" "php8.2-mysql"
            "php8.2-opcache" "php8.2-xml" "php8.2-zip" "php8.2-bz2"
            "libapache2-mod-php8.2" "php8.2-ldap" "php8.2-xmlrpc"
            "php8.2-soap" "php8.2-apcu" "php8.2-imagick" "php8.2-bcmath"
            "php8.2-gmp" "php8.2-igbinary" "php8.2-imap" "php8.2-redis"
            "php8.2-xsl" "php-pear"
        )

        if ! env DEBIAN_FRONTEND=noninteractive apt-get install -y "${PHP_PACKAGES[@]}"; then
            echo_error "Failed to install php package"
            return 1
        fi
        echo_success "PHP packages installed."


        echo_info "Restarting Apache to apply configuration..."
        if ! systemctl restart apache2; then
            echo_error "Apache failed to restart. Check configuration."
            return 1
        fi

        return 0
    }

    install_php82

}

main