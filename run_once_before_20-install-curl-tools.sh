#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/bin"

install_atuin() {
    if command -v atuin &>/dev/null; then
        echo "atuin already installed"
        return 0
    fi
    # https://docs.atuin.sh/guide/installation/
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

install_claude() {
    if command -v claude &>/dev/null; then
        echo "claude already installed"
        return 0
    fi
    # https://docs.anthropic.com/en/docs/claude-code
    curl -fsSL https://claude.ai/install.sh | bash
}

install_uv() {
    if command -v uv &>/dev/null; then
        echo "uv already installed"
        return 0
    fi
    # https://docs.astral.sh/uv/getting-started/installation/
    wget -qO- https://astral.sh/uv/install.sh | sh
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo "nvm already installed"
        return 0
    fi
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_k3d() {
    if command -v k3d &>/dev/null; then
        echo "k3d already installed"
        return 0
    fi
    # https://k3d.io/stable/
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_syft() {
    if command -v syft &>/dev/null; then
        echo "syft already installed"
        return 0
    fi
    # https://github.com/anchore/syft
    curl -sSfL https://get.anchore.io/syft | sudo sh -s -- -b /usr/local/bin
}

install_grype() {
    if command -v grype &>/dev/null; then
        echo "grype already installed"
        return 0
    fi
    # https://github.com/anchore/grype
    curl -sSfL https://get.anchore.io/grype | sh -s -- -b "$HOME/.local/bin"
}

install_atuin
install_claude
install_uv
install_nvm
install_k3d
install_syft
install_grype
