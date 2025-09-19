#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$THIS_DIR/../bootstrap.sh"
require "functions/functions.sh"

need_sudo || exit 1

install_docker() {
  echo_note "Removing conflicting Docker/Container packages (if any)..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" >/dev/null 2>&1 || true
  done

  echo_note "Installing prerequisites..."
  apt_update
  apt_install ca-certificates curl gnupg

  echo_note "Setting up Docker apt repository..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  ARCH="$(dpkg --print-architecture)"
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  apt_update
  echo_note "Installing Docker CE and plugins..."
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo_note "Enabling and starting Docker..."
  sudo systemctl enable --now docker

  echo_success "Docker installed."
  docker -v || true

  # Offer to add the invoking user to docker group
  TARGET_USER="${SUDO_USER:-$USER}"
  if id -nG "$TARGET_USER" | grep -qw docker; then
    echo_info "User '$TARGET_USER' is already in 'docker' group."
  else
    if confirm "Add '$TARGET_USER' to 'docker' group (use Docker without sudo)?"; then
      sudo usermod -aG docker "$TARGET_USER"
      echo_note "You'll need to log out & back in (or 'newgrp docker') for group changes to take effect."
    fi
  fi
}

install_docker