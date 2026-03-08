# admin-kit

A Bash admin toolkit with one interactive menu entrypoint.

## Supported entrypoint

- `./admin_menu.sh`

No CLI-only entrypoint scripts are currently supported.

## Supported menu options and script dispatch

The options below are the supported menu flows and dispatch targets from `admin_menu.sh`.

- Main menu `1) SYSTEM`
  - `1) System update and upgrade` → `scripts/system/update_system.sh`
  - `2) Create user with sudo privileges` → `scripts/system/create_user.sh`
  - `3) Set timezone` → `scripts/system/set_timezone.sh`
  - `4) Set hostname` → `scripts/system/set_hostname.sh`
  - `5) Install common packages` → `scripts/system/common_packages.sh`
- Main menu `2) WEBSERVER PACKAGES (APACHE/NGINX)`
  - `1) Install Apache2` → `scripts/webserver/apache2.sh`
  - `2) Install Nginx` → `scripts/webserver/nginx.sh`
  - `3) Install Certbot (Let's Encrypt)` → `scripts/webserver/certbot.sh`
- Main menu `3) DATABASE SERVERS (MYSQL/MARIADB/POSTGRESQL)`
  - `1) Install MariaDB` → `scripts/databases/install_mariadb.sh`
  - `2) Install MySQL` → `scripts/databases/install_mysql.sh`
  - `3) Install PostgreSQL` → `scripts/databases/install_postgresql.sh`
- Main menu `4) SERVER HARDENING`
  - `1) Disable root SSH login` → `scripts/security/ssh_disable_root.sh`
  - `2) Install fail2ban` → `scripts/security/install_fail2ban.sh`
  - `3) Install UFW` → `scripts/security/install_ufw.sh`
- Main menu `6) DEVELOPER TOOLS (NODE.JS, COMPOSER, PHP, PYTHON, ETC.) --IN DEVELOPMENT`
  - `1) Install Extrepo (external apt repositories)` → `scripts/developer/install_extrepo.sh`
  - `2) Install PHP and common extensions` → `scripts/developer/install_php.sh`
  - `3) Install Composer` → `scripts/developer/install_composer.sh`
  - `4) Install Node.js and npm` → `scripts/developer/install_nodejs.sh`
  - `5) Install Symfony-CLI` → `scripts/developer/install_symfony.sh`
- Main menu `7) CUSTOM SCRIPTS --IN DEVELOPMENT`
  - `1) Custom Quick Install ILIAS LMS` → `scripts/custom/ilias.sh`

## Unsupported / removed workflows

- `dodb.sh` is not present in this repository, is not wired in `admin_menu.sh`, and is not a supported entrypoint.
- Main menu `5) BACKUPS --IN DEVELOPMENT` currently displays a placeholder screen only and does not dispatch to any install/configuration script.
- Scripts under `scripts/helper/` and helper scripts under `scripts/custom/` are internal implementation helpers, not user entrypoints.
