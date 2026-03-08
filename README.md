# admin-kit

A Bash admin toolkit with one interactive entrypoint and one shared library stack.

## Supported entrypoint

- `./admin_menu.sh`

No additional standalone CLI entrypoints are supported.

## Canonical architecture

- `scripts/bootstrap.sh` is the only loader.
- `lib/*.sh` modules are the only shared helper APIs.
- Top-level action scripts live under `scripts/{system,webserver,databases,security,developer,custom}`.
- OS/distro differences are handled in `lib/os.sh` through capability resolvers (`os_resolve_pkg`, `os_resolve_service`) and backend detection.
- Package and service operations are centralized in `lib/pkg.sh` and `lib/service.sh`.

## Menu dispatch map

The menu is generated from one authoritative dispatch table in `admin_menu.sh`.
Options are shown only when the mapped script exists and is executable.

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
