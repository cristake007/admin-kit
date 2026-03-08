#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

SSHD_CFG="/etc/ssh/sshd_config"
SSHD_DIR="/etc/ssh/sshd_config.d"
DROPIN="$SSHD_DIR/99-admin-kit.conf"
BACKUP="$SSHD_CFG.admin-kit.bak"

main() {
  # Explain (always)
  echo_info "This disables SSH root login by writing a drop-in: $DROPIN"
  echo_info "It will back up $SSHD_CFG to $BACKUP (once) and reload SSH."
  echo_info "IMPORTANT: Have a sudo-capable non-root user first."

  # Single confirmation first
  if ! confirm "Proceed?"; then
    echo_info "Cancelled."
    exit 0
  fi

  # Safety: require a sudo-capable non-root user after user chose to proceed
  if ! has_sudo_user; then
    echo_error "No non-root sudo user detected (groups: sudo/wheel)."
    exit 0
  fi

  need_sudo || exit 1

  # Idempotency: already disabled?
  if [[ -f "$DROPIN" ]] && grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no([[:space:]]|$)' "$DROPIN"; then
    echo_success "Root SSH login already disabled. Nothing to do."
    exit 0
  fi

  # Do the work
  sudo mkdir -p "$SSHD_DIR"

  # Backup main config once
  if [[ -f "$SSHD_CFG" && ! -f "$BACKUP" ]]; then
    echo_info "Backing up $SSHD_CFG -> $BACKUP"
    sudo cp -a "$SSHD_CFG" "$BACKUP"
  fi

  # Ensure Include directive exists (append if missing)
  if ! grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CFG"; then
    printf "\nInclude /etc/ssh/sshd_config.d/*.conf\n" | sudo tee -a "$SSHD_CFG" >/dev/null
  fi

  # Write drop-in (confirmed already)
  sudo tee "$DROPIN" >/dev/null <<'EOF'
# Managed by admin-kit
PermitRootLogin no
EOF
  sudo chmod 0644 "$DROPIN"

  # Validate and reload
  if ! sudo sshd -t 2>/tmp/sshd_test.err; then
    echo_error "sshd config test failed:"
    cat /tmp/sshd_test.err >&2 || true
    sudo rm -f /tmp/sshd_test.err "$DROPIN" || true
    exit 1
  fi
  rm -f /tmp/sshd_test.err || true

  sudo systemctl reload ssh 2>/dev/null || sudo systemctl reload sshd 2>/dev/null \
    || sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd

  echo_success "Root SSH login disabled via $DROPIN. Current sessions remain active."
}

main "$@"