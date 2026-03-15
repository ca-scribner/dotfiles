#!/bin/bash
set -euo pipefail

# https://brew.sh/
if command -v brew &>/dev/null; then
    echo "Homebrew already installed"
    exit 0
fi

# Unattended install: https://docs.brew.sh/Installation#unattended-installation
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sudo apt-get install -y build-essential
