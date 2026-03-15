#!/bin/bash
set -euo pipefail

# Core packages available directly from Ubuntu apt repos
PACKAGES=(
    curl
    ca-certificates
    git-all
    jq
    make
    meld
    maven
    nodejs
    npm
    qemu-system
    xournalpp
    yubikey-manager
)

sudo apt-get update
sudo apt-get install -y "${PACKAGES[@]}"
