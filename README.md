# admin-kit

A bash admin kit menu that helps install and configure common server packages.

## Entry points

- `./admin_menu.sh` — main interactive menu for system/web/database/security/developer tasks.
- `./dodb.sh` — quick interactive helper to create database + user credentials for:
  - MySQL
  - MariaDB
  - PostgreSQL

## dodb.sh purpose

`dodb.sh` is intended as your future default workflow for database provisioning so users do not need to remember raw SQL/CLI commands.
It prompts for engine, database name, username, and password, then creates/grants safely.
