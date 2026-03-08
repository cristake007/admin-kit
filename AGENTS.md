# AGENTS.md

## Mission

This repository is a Bash-based admin toolkit. The current codebase is organized around one interactive entrypoint (`admin_menu.sh`), a shared bootstrap loader (`scripts/bootstrap.sh`), a shared function library (`functions/functions.sh`), and grouped task scripts under `scripts/system`, `scripts/webserver`, `scripts/databases`, `scripts/security`, `scripts/developer`, `scripts/helper`, and `scripts/custom`.

Your job is to refactor the entire repository to one unified engineering standard with these goals:

1. remove dead or unused code,
2. improve reliability and failure handling,
3. eliminate complicated or fragile logic,
4. make scripts idempotent,
5. broaden Linux compatibility beyond Debian/Ubuntu where practical,
6. keep the UX simple and predictable.

Do not preserve legacy behavior just because it exists. Preserve only behavior that is clearly used, safe, and coherent.

---

## What exists today

### Observed structure

- `README.md`
- `admin_menu.sh`
- `functions/functions.sh`
- `scripts/bootstrap.sh`
- `scripts/system/*`
- `scripts/webserver/*`
- `scripts/databases/*`
- `scripts/security/*`
- `scripts/developer/*`
- `scripts/helper/*`
- `scripts/custom/*`

### Current main menu wiring

`admin_menu.sh` currently calls scripts from these areas:

- system: update, create user, timezone, hostname, common packages
- webserver: Apache, Nginx, Certbot
- databases: MariaDB, MySQL, PostgreSQL
- security: disable root SSH login, Fail2Ban, UFW
- developer: Extrepo, PHP, Composer, Node.js, Symfony CLI
- custom: ILIAS installer

Anything not reachable from the main menu or from a reachable script should be treated as a removal candidate.

### Current technical traits

- The repository is Bash-only.
- `scripts/bootstrap.sh` discovers the project root via `.project-root` or `.git` and exposes a `require()` helper.
- `functions/functions.sh` currently centralizes logging, prompts, privilege checks, APT helpers, environment persistence helpers, file utilities, and a generic runner.
- Package management is currently strongly APT-centric.
- MySQL repository setup is explicitly Debian Bookworm specific.
- Some files in the tree appear to be experimental, duplicated, or placeholder-like and should not survive unless proven necessary.

---

## Mandatory end state

### 1) One repo-wide standard

All executable scripts must follow the same standard:

- `#!/usr/bin/env bash`
- `set -Eeuo pipefail`
- consistent quoting
- no hidden globals unless explicitly declared constants
- one `main()` per executable script
- shared helper library for all common operations
- no duplicated helper logic across scripts
- no commented-out legacy blocks kept “just in case”
- no placeholder scripts such as `script1.sh`, `script2.sh`, `script3.sh`
- ShellCheck-clean where reasonably possible

### 2) Idempotency everywhere

Every script must be safe to rerun.

Examples:

- installing a package must first detect whether it is already installed,
- editing a config file must not append duplicate lines,
- creating users, groups, directories, services, or firewall rules must check current state first,
- enabling a service must not fail if already enabled,
- repository setup must not add duplicate repo definitions,
- backups must not overwrite prior backups blindly.

Every script should prefer “detect -> compare -> change only if needed”.

### 3) Linux compatibility

Refactor package and service management to support at least these families cleanly:

- Debian/Ubuntu
- RHEL/Rocky/Alma/Fedora
- openSUSE where feasible
- Arch only when support is easy and low-risk

Implement a distro abstraction layer. Do not scatter `apt`, `dnf`, `yum`, `zypper`, `pacman`, or service differences throughout the repo.

Create one shared compatibility module that detects:

- distro family
- package manager
- service manager
- firewall tool
- package names that differ across distros

If a feature cannot be supported safely on a distro, fail clearly with a short explanation.

### 4) No complicated formulas or cleverness

Prefer simple, explicit Bash over compressed one-liners or tricky conditionals.

Rules:

- no dense command chains that hide failure modes,
- no brittle parsing when a simple command exists,
- no terminal-width math unless it degrades gracefully,
- no unnecessary traps or abstractions,
- no self-modifying behavior,
- no hidden side effects.

Readable beats clever.

### 5) Stability first

Refactor to minimize partial-change failure states.

Required patterns:

- validate prerequisites before mutating,
- create backups before editing managed config files,
- use clear rollback notes where full rollback is not realistic,
- emit deterministic logs,
- return non-zero on real failure,
- never rely on interactive prompts inside low-level helper functions,
- keep user prompts only in top-level menu or explicitly interactive workflows.

### 6) Dead code removal

Remove code that is not used.

Perform a real reachability audit:

1. inventory every script,
2. trace references from entrypoints,
3. trace `source`, `require`, and script-to-script calls,
4. delete files not reachable from supported workflows,
5. update README and menus accordingly.

Do not keep "maybe useful later" files.

---

## Required target architecture

Refactor toward this shape:

```text
admin_menu.sh
lib/
  core.sh
  log.sh
  ui.sh
  os.sh
  pkg.sh
  service.sh
  file.sh
  validate.sh
scripts/
  system/
  webserver/
  databases/
  security/
  developer/
  custom/
```

Notes:

- `functions/functions.sh` should be split by responsibility or replaced by `lib/*.sh` modules.
- `scripts/bootstrap.sh` may stay only if it remains minimal and clear. If it becomes redundant, remove it.
- `helper/` should disappear unless its contents become first-class library modules.
- orphaned experimental scripts should be deleted.

---

## Behavioral rules for Codex

### Entrypoints

Support these entrypoints only if they are real and documented:

- `admin_menu.sh`
- any clearly supported non-menu executable such as `dodb.sh` if it still exists and is kept

Everything else should be treated as an internal module or removed.

### Script metadata

At the top of every executable script, keep a short header block with only useful fields:

- Purpose
- Supports
- Requires
- Safe to rerun
- Side effects

Do not generate verbose banners.

### Logging

Use one shared logging format:

- `info`
- `warn`
- `error`
- `success`

No mixed naming. No duplicated color code definitions across files.

### Prompts

Interactive confirmation belongs only in user-facing flows.

Low-level helpers must never prompt.
They should accept arguments, perform checks, and return status.

### Config edits

Use helper functions for safe config mutations:

- ensure line exists once,
- replace key/value safely,
- backup before edit,
- validate syntax when possible before restart.

### Services

Use shared helpers for:

- `service_exists`
- `service_is_active`
- `service_enable_now`
- `service_restart_if_present`

Never inline service-manager-specific commands in many places.

### Packages

Use shared helpers for:

- `pkg_update_index`
- `pkg_install`
- `pkg_remove`
- `pkg_is_installed`
- `pkg_add_repo`

Map package names per distro family in one place.

---

## Concrete cleanup directives

### Remove or rewrite likely problem areas

The current repository strongly suggests several cleanup targets:

- placeholder files in `scripts/custom/` such as `script1.sh`, `script2.sh`, `script3.sh`
- helper files that duplicate library responsibilities
- developer scripts present in the tree but not exposed in the menu, unless they are intentionally supported and documented
- Debian-only repo setup embedded in generic helpers
- functions with mixed concerns packed into one giant file

When in doubt, prefer deletion plus a small, clean replacement over preserving messy compatibility glue.

### Menu cleanup

The menu must only show supported, tested actions.

- remove “in development” items unless they are actually implemented,
- fix numbering inconsistencies,
- ensure every menu item maps to an existing script,
- ensure hidden scripts are either removed or intentionally documented as CLI-only.

### Database scripts

Database installers must be simplified:

- install package(s),
- enable/start service if applicable,
- show resulting status,
- avoid distro-specific repo hacks unless absolutely required,
- avoid advanced tuning during initial install.

### Webserver scripts

Apache and Nginx installers must:

- detect conflicts clearly,
- avoid destructive changes,
- report service status,
- not assume Debian filesystem layout outside Debian family.

### Security scripts

Security scripts must be extra conservative.

- never lock out SSH access without clear checks,
- validate SSH config before reload/restart,
- firewall changes must be additive and state-aware,
- rerunning must not duplicate rules.

---

## Acceptance criteria

A refactor is complete only when all of the following are true:

1. every supported script is ShellCheck-clean or has minimal justified exceptions,
2. rerunning any supported script causes no harmful duplication,
3. unsupported distros fail gracefully and early,
4. supported distros use a shared abstraction layer,
5. no placeholder or unreachable scripts remain,
6. README matches actual behavior,
7. menu items exactly match supported scripts,
8. helpers are modular and single-purpose,
9. no script contains complicated inline formulas or brittle parsing where a simpler approach exists,
10. failures are understandable from the console output.

---

## Recommended execution plan

Follow this order:

1. inventory files and call graph,
2. identify supported workflows,
3. delete dead code,
4. extract shared library modules,
5. add distro abstraction,
6. refactor each script to idempotent state-aware behavior,
7. simplify menu,
8. update README,
9. run ShellCheck,
10. perform rerun tests on supported workflows.

---

## Definition of done for each script

Before marking any script complete, verify:

- it has a clear purpose,
- it has no duplicated helper logic,
- it does not prompt unexpectedly from internal functions,
- it can be run twice safely,
- it handles missing tools gracefully,
- it supports the distro abstraction or fails explicitly,
- it logs what changed and what was skipped.

---

## Final instruction

Be willing to remove more code than you keep.
This repository should become smaller, more uniform, and more dependable after the refactor.
