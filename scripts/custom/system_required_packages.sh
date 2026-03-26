#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
PACKAGES=(imagemagick ghostscript graphicsmagick wkhtmltopdf libjs-mathjax libreoffice libreoffice-writer htmldoc abiword xpdf poppler-utils ffmpeg sox html2text clamav clamav-daemon openjdk-17-jdk xvfb tidy maven)
check_installed(){ local p; for p in "${PACKAGES[@]}"; do apt_package_installed "$p" || return 1; done; return 0; }
check_conflicts(){ return 0; }
install_step(){ local missing=() p; for p in "${PACKAGES[@]}"; do apt_package_installed "$p" || missing+=("$p"); done; [[ ${#missing[@]} -eq 0 ]] && return 0; apt_update; apt_install "${missing[@]}"; wf_mark_changed "Installed required ILIAS packages"; }
summary_step(){ wf_default_summary "$1" "$2"; }
main(){ echo_info "This script installs required system packages for ILIAS LMS."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "ilias_system_packages" check_installed check_conflicts install_step summary_step; }
main "$@"
