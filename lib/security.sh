#!/usr/bin/env bash

[[ -n "${__LIB_SECURITY_SH:-}" ]] && return 0
__LIB_SECURITY_SH=1

configure_firewall() {
  if command_exists ufw; then
    echo_note "Ensuring UFW allows HTTP/HTTPS..."
    sudo ufw allow 80/tcp || true
    sudo ufw allow 443/tcp || true
    sudo ufw reload || true
  fi
}