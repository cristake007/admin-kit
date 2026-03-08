#!/usr/bin/env bash
set -Eeuo pipefail

THIS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$THIS_DIR/../bootstrap.sh"
require "lib/log.sh"
require "lib/ui.sh"
require "lib/core.sh"
require "lib/pkg.sh"
require "lib/service.sh"
trap err_trap ERR

need_sudo || exit 1

main() {
  local codename arch target_user
  echo_info "This installs Docker CE from Docker's APT repository."
  echo

  confirm "Do you want to continue?" || { echo_info "Cancelled."; exit 0; }

  if apt_is_installed docker-ce; then
    echo_success "Docker CE is already installed."
    service_enable_now docker
    docker -v || true
  else
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
      sudo apt-get remove -y "$pkg" >/dev/null 2>&1 || true
    done

    apt_update
    apt_install ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    arch="$(dpkg --print-architecture)"
    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${codename} stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    apt_update
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    service_enable_now docker
    echo_success "Docker installed."
    docker -v || true
  fi

  target_user="${SUDO_USER:-$USER}"
  if id -nG "$target_user" | grep -qw docker; then
    echo_info "User '$target_user' is already in 'docker' group."
  elif confirm "Add '$target_user' to 'docker' group (use Docker without sudo)?"; then
    sudo usermod -aG docker "$target_user"
    echo_note "Log out and back in (or run 'newgrp docker') for group change to apply."
  fi
}

main "$@"
