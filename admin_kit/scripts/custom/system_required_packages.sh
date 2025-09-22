#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

main() {
echo_info "This script installs all required packages for Ilias LMS."

packages=( 
    "imagemagick" "ghostscript" "graphicsmagick" "wkhtmltopdf" "libjs-mathjax"
    "libreoffice" "libreoffice-writer"  "htmldoc" "abiword" "xpdf" "poppler-utils"
    "ffmpeg" "sox" "html2text"
    "clamav" "clamav-daemon"
    "openjdk-17-jdk" "xvfb" "tidy" "maven"
    
)

install_items package "${packages[@]}" || {
  echo_error "Error installing system packages"
  exit 1
}
echo_success "All required packages installed successfully."
}
main