# admin-kit

A bash admin kit menu that helps install and configure common server packages.

## Entry points

- `./admin_menu.sh` — main interactive menu for system/web/database/security/developer tasks.
- `./dodb.sh` — quick interactive helper to create database + user credentials for:
  - MySQL
  - MariaDB
  - PostgreSQL

## Project features

- **State-aware menus** for key components (installed/running markers for web/database/security/developer items).
- **Portable terminal header rendering** with a fallback width when `tput cols` is not available.
- **Root-aware privileged execution helpers** so package actions can run as root directly (without forcing `sudo`) and use `sudo` only when needed.
- **Script metadata contract** (`Requires`, `Privileges`, `Target distro`, `Side effects`, `Safe to re-run`) available as header comments and via runtime helper output (`show_script_metadata`).

## dodb.sh purpose

`dodb.sh` is intended as your future default workflow for database provisioning so users do not need to remember raw SQL/CLI commands.
It prompts for engine, database name, username, and password, then creates/grants safely.
