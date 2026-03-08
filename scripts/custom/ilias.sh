#!/usr/bin/env bash
set -Eeuo pipefail
# Purpose: Run a safe baseline ILIAS dependency workflow.
# Supports: debian, rhel, suse
# Requires: root privileges
# Safe to rerun: yes
# Side effects: installs packages and creates directories

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require_lib log
require_lib core

main() {
  need_root

  run_script scripts/custom/env_file.sh
  run_script scripts/custom/create_directories.sh
  run_script scripts/webserver/apache2.sh
  run_script scripts/developer/install_php.sh
  run_script scripts/databases/install_mariadb.sh
  run_script scripts/custom/system_required_packages.sh

  success "ILIAS quick baseline workflow completed."
}

main "$@"
