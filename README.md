# admin-kit

A Bash admin toolkit with one interactive entrypoint and a curated set of supported workflows.

## Supported entrypoints (final allowlist)

- `./admin_menu.sh` — primary and only supported user entrypoint.

There are currently no intentionally supported CLI-only entrypoint scripts.

## Supported workflows (menu-backed)

The following scripts are the supported workflows reachable from `admin_menu.sh`:

- System
  - `scripts/system/update_system.sh`
  - `scripts/system/create_user.sh`
  - `scripts/system/set_timezone.sh`
  - `scripts/system/set_hostname.sh`
  - `scripts/system/common_packages.sh`
- Webserver
  - `scripts/webserver/apache2.sh`
  - `scripts/webserver/nginx.sh`
  - `scripts/webserver/certbot.sh`
- Databases
  - `scripts/databases/install_mariadb.sh`
  - `scripts/databases/install_mysql.sh`
  - `scripts/databases/install_postgresql.sh`
- Security
  - `scripts/security/ssh_disable_root.sh`
  - `scripts/security/install_fail2ban.sh`
  - `scripts/security/install_ufw.sh`
- Developer
  - `scripts/developer/install_extrepo.sh`
  - `scripts/developer/install_php.sh`
  - `scripts/developer/install_composer.sh`
  - `scripts/developer/install_nodejs.sh`
  - `scripts/developer/install_symfony.sh`
- Custom
  - `scripts/custom/ilias.sh`

## Internal support modules

These are internal modules used by supported workflows and are not user entrypoints:

- `scripts/bootstrap.sh`
- `functions/functions.sh`
- `scripts/custom/env_file.sh`
- `scripts/custom/create_directories.sh`
- `scripts/custom/system_required_packages.sh`
- `scripts/helper/install_common_tools.sh`
