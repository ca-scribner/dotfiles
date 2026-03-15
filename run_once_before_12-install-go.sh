#!/bin/bash
set -euo pipefail

# https://go.dev/doc/install
GO_VERSION="1.25.4"

if command -v go &>/dev/null; then
    INSTALLED="$(go version | grep -oP 'go\K[0-9]+\.[0-9]+\.[0-9]+')"
    if [[ "$INSTALLED" == "$GO_VERSION" ]]; then
        echo "Go ${GO_VERSION} already installed"
        exit 0
    fi
    echo "Upgrading Go from ${INSTALLED} to ${GO_VERSION}"
fi

# Remove any apt-installed Go to avoid conflicts
sudo apt-get remove -y golang-go 2>/dev/null || true

TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
curl -Lo "/tmp/${TARBALL}" "https://go.dev/dl/${TARBALL}"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "/tmp/${TARBALL}"
rm "/tmp/${TARBALL}"

echo "Go ${GO_VERSION} installed to /usr/local/go"
