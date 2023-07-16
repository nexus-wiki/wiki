#!/bin/bash
set -eou pipefail

_install_dependencies() {
  if ! docker compose --version >/dev/null 2>&1 >/dev/null 2>&1; then
    printf "%s\n" "INFO : Installing docker compose..."
    apt -yqq update
    apt install -yqq ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt update
    apt install -yqq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    groupadd docker
    usermod -aG docker $USER
    newgrp docker
  fi
  if ! command -V git >/dev/null 2>&1; then
    printf "%s\n" "INFO : Installing git..."
    apt -yqq update
    apt install -yqq git
  fi
  if ! command -V openssl >/dev/null 2>&1; then
    printf "%s\n" "INFO : Installing openssl..."
    apt -yqq update
    apt install -yqq openssl
  fi
  if ! command -V tar >/dev/null 2>&1; then
    printf "%s\n" "INFO : Installing tar..."
    apt -yqq update
    apt install -yqq tar
  fi
}

_install_dependencies

printf "%s\n" "INFO : Nexus Wiki setup finished successfully"
