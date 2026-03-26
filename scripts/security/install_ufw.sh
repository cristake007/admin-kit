#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/validate.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
SSH_PORT="22"; WEB="Y"

check_installed(){ command_exists ufw || [[ -x /usr/sbin/ufw ]]; }
check_conflicts(){ return 0; }
rule_exists(){ sudo /usr/sbin/ufw status | grep -q "$1"; }
install_step(){
  command_exists ufw || { apt_update; apt_install ufw; wf_mark_changed "Installed UFW"; }
  sudo /usr/sbin/ufw default deny incoming >/dev/null
  sudo /usr/sbin/ufw default allow outgoing >/dev/null
  rule_exists "${SSH_PORT}/tcp" || { sudo /usr/sbin/ufw allow "${SSH_PORT}/tcp" >/dev/null; wf_mark_changed "Allowed SSH ${SSH_PORT}/tcp"; }
  if [[ "$WEB" =~ ^[Yy]$ ]]; then
    rule_exists "80/tcp" || { sudo /usr/sbin/ufw allow 80/tcp >/dev/null; wf_mark_changed "Allowed HTTP 80/tcp"; }
    rule_exists "443/tcp" || { sudo /usr/sbin/ufw allow 443/tcp >/dev/null; wf_mark_changed "Allowed HTTPS 443/tcp"; }
  fi
  sudo /usr/sbin/ufw --force enable >/dev/null
}
summary_step(){ wf_default_summary "$1" "$2"; sudo /usr/sbin/ufw status verbose; }

main(){
  echo_info "UFW basic setup (idempotent safe defaults)."; confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }
  while true; do read -r -p "SSH port [22]: " SSH_PORT; SSH_PORT="${SSH_PORT:-22}"; validate_port "$SSH_PORT" && break; echo_error "Invalid port. Enter a value between 1 and 65535."; done
  read -r -p "Allow HTTP+HTTPS (80/443)? (Y/n): " WEB; WEB="${WEB:-Y}"
  run_install_workflow "ufw" check_installed check_conflicts install_step summary_step
}
main "$@"
