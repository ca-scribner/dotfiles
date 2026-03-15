#!/bin/bash
set -euo pipefail

if command -v google-chrome &>/dev/null; then
    echo "Chrome already installed"
    exit 0
fi

TEMP_DEB=$(mktemp --suffix=.deb)
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$TEMP_DEB"
sudo dpkg -i "$TEMP_DEB" || sudo apt-get install -f -y
rm "$TEMP_DEB"
