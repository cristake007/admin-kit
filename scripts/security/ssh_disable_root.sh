#!/usr/bin/env bash
set -Eeuo pipefail
THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"; require "lib/ui.sh"; require "lib/core.sh"; require "lib/service.sh"; require "lib/workflow.sh"
trap err_trap ERR
SSHD_CFG="/etc/ssh/sshd_config"; SSHD_DIR="/etc/ssh/sshd_config.d"; DROPIN="$SSHD_DIR/99-admin-kit.conf"; BACKUP="$SSHD_CFG.admin-kit.bak"
check_installed(){ [[ -f "$DROPIN" ]] && grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' "$DROPIN"; }
check_conflicts(){ has_sudo_user; }
install_step(){ need_sudo || return 1; sudo mkdir -p "$SSHD_DIR"; [[ -f "$SSHD_CFG" && ! -f "$BACKUP" ]] && sudo cp -a "$SSHD_CFG" "$BACKUP"; grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CFG" || printf "\nInclude /etc/ssh/sshd_config.d/*.conf\n" | sudo tee -a "$SSHD_CFG" >/dev/null; sudo tee "$DROPIN" >/dev/null <<'CONF'
# Managed by admin-kit
PermitRootLogin no
CONF
sudo chmod 0644 "$DROPIN"; sudo sshd -t; service_reload_or_restart ssh || service_reload_or_restart sshd; wf_mark_changed "Disabled root SSH login via drop-in"; }
summary_step(){ wf_default_summary "$1" "$2"; echo_note "Drop-in: $DROPIN"; }
main(){ echo_info "This disables SSH root login by writing: $DROPIN"; confirm "Proceed?" || { echo_info "Cancelled."; exit 0; }; run_install_workflow "ssh_disable_root" check_installed check_conflicts install_step summary_step; }
main "$@"
