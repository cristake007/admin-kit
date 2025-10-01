#!/usr/bin/env bash
set -Euo pipefail

echo "Creating project-root file"
touch .project-root
echo "Starting AdminKit"
bash admin_menu.sh
