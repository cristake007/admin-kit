#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  local packages=(
    imagemagick ghostscript graphicsmagick wkhtmltopdf libjs-mathjax
    libreoffice libreoffice-writer htmldoc abiword xpdf poppler-utils
    ffmpeg sox html2text
    clamav clamav-daemon
    openjdk-17-jdk xvfb tidy maven
  )

  echo_info "This script installs required system packages for ILIAS LMS."
  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  install_items package "${packages[@]}"
  echo_success "All required packages installed successfully."
}

main "$@"
