# admin-kit

A Bash admin toolkit with one interactive menu entrypoint.

## Supported entrypoint

- `./admin_menu.sh`

No CLI-only entrypoint scripts are currently supported.

## Menu dispatch map

- `System`
  - `Update system` → `scripts/system/update_system.sh`
  - `Create privileged user` → `scripts/system/create_user.sh`
  - `Set timezone` → `scripts/system/set_timezone.sh`
  - `Set hostname` → `scripts/system/set_hostname.sh`
  - `Install common packages` → `scripts/system/common_packages.sh`
- `Webserver`
  - `Install Apache` → `scripts/webserver/apache2.sh`
  - `Install Nginx` → `scripts/webserver/nginx.sh`
  - `Install Certbot` → `scripts/webserver/certbot.sh`
- `Databases`
  - `Install MariaDB` → `scripts/databases/install_mariadb.sh`
  - `Install MySQL` → `scripts/databases/install_mysql.sh`
  - `Install PostgreSQL` → `scripts/databases/install_postgresql.sh`
- `Security`
  - `Disable SSH root login` → `scripts/security/ssh_disable_root.sh`
  - `Install fail2ban` → `scripts/security/install_fail2ban.sh`
  - `Install firewall tooling` → `scripts/security/install_ufw.sh`
- `Developer`
  - `Install extrepo` → `scripts/developer/install_extrepo.sh`
  - `Install PHP` → `scripts/developer/install_php.sh`
  - `Install Composer` → `scripts/developer/install_composer.sh`
  - `Install Node.js` → `scripts/developer/install_nodejs.sh`
  - `Install Symfony prerequisites` → `scripts/developer/install_symfony.sh`
- `Custom`
  - `ILIAS baseline workflow` → `scripts/custom/ilias.sh`

## Internal modules

- Shared code lives in `lib/*.sh` modules and is loaded via `scripts/bootstrap.sh`.
- Helper workflows used by top-level scripts remain under `scripts/custom/`.
