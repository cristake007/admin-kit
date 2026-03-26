#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/validate.sh"; require "lib/security.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1

check_installed(){ apt_package_installed certbot; }
check_conflicts(){ detect_server; }
install_step(){
  apt_update; apt_install certbot
  if [[ "$SERVER" == "apache" ]]; then apt_package_installed python3-certbot-apache || apt_install python3-certbot-apache; service_enable_now apache2 || true; else apt_package_installed python3-certbot-nginx || apt_install python3-certbot-nginx; service_enable_now nginx || true; fi
  configure_firewall
  wf_mark_changed "Installed Certbot for ${SERVER}"
}
summary_step(){ wf_default_summary "$1" "$2"; [[ "$SERVER" == "apache" ]] && service_status_line apache2 || service_status_line nginx; }
maybe_run_certbot_now(){ local flag; [[ "$SERVER" == "apache" ]] && flag="--apache" || flag="--nginx"; if confirm "Run Certbot now to obtain/renew certificates and auto-configure ${SERVER}?"; then sudo certbot "$flag"; sudo certbot renew --dry-run || echo_error "Renewal dry-run reported issues."; fi; }
main(){ echo_info "This installs Certbot for Apache or Nginx."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "certbot" check_installed check_conflicts install_step summary_step; maybe_run_certbot_now; }
main "$@"
