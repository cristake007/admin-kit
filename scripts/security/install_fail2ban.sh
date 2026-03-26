#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/pkg.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
need_sudo || exit 1
JAIL_DIR="/etc/fail2ban/jail.d"; JAIL_FILE="$JAIL_DIR/00-admin-kit-sshd.conf"
is_fail2ban_operational(){ service_is_active fail2ban && sudo fail2ban-client ping >/dev/null 2>&1 && sudo fail2ban-client status sshd >/dev/null 2>&1; }
check_installed(){ apt_package_installed fail2ban && [[ -f "$JAIL_FILE" ]] && is_fail2ban_operational; }
check_conflicts(){ return 0; }
install_step(){ apt_update; apt_install fail2ban python3-systemd; sudo mkdir -p "$JAIL_DIR"; sudo tee "$JAIL_FILE" >/dev/null <<'JAIL'
# Managed by admin-kit
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
backend  = systemd
JAIL
sudo fail2ban-client -t; service_enable_now fail2ban; is_fail2ban_operational; wf_mark_changed "Configured Fail2Ban SSH jail"; }
summary_step(){ wf_default_summary "$1" "$2"; service_status_line fail2ban; sudo fail2ban-client status sshd || true; }
main(){ echo_info "This installs Fail2Ban, configures a basic SSH jail, and enables the service."; confirm "Proceed?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "fail2ban" check_installed check_conflicts install_step summary_step; }
main "$@"
