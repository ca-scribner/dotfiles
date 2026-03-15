#!/bin/bash
set -euo pipefail

# Chainguard-specific tools. These require gh auth and chainctl to be set up
# already, so they run late in the sequence.

install_chainctl() {
    if command -v chainctl &>/dev/null; then
        echo "chainctl already installed"
        return 0
    fi
    curl -o /tmp/chainctl "https://dl.enforce.dev/chainctl/latest/chainctl_$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m | sed 's/aarch64/arm64/')"
    sudo install -o "$UID" -g "$(id -g)" -m 0755 /tmp/chainctl /usr/local/bin/
    rm /tmp/chainctl

    echo ""
    echo "NOTE: Run 'chainctl auth login' manually to authenticate"
}

install_cg_tokens() {
    if command -v cg-tokens &>/dev/null; then
        echo "cg-tokens already installed"
        return 0
    fi
    if ! command -v gh &>/dev/null; then
        echo "ERROR: gh required for cg-tokens — skipping"
        return 1
    fi
    if ! command -v chainctl &>/dev/null; then
        echo "ERROR: chainctl required for cg-tokens — skipping"
        return 1
    fi

    # https://github.com/chainguard-dev/sandbox-of-power/tree/main/martin.wimpress/cg-tokens
    chainctl config set default.social-login google-oauth2

    TEMPFILE=$(mktemp)
    wget \
      --header="Authorization: token $(gh auth token)" \
      -O "$TEMPFILE" \
      https://raw.githubusercontent.com/chainguard-dev/sandbox-of-power/refs/heads/main/martin.wimpress/cg-tokens/cg-tokens.sh
    chmod +x "$TEMPFILE"
    mv "$TEMPFILE" "$HOME/.local/bin/cg-tokens"
}

install_wolfi_rc() {
    local TARGET_DIR="$HOME/code/wolfi-rc/wolfi-rc"
    if [ -d "$TARGET_DIR/main" ]; then
        echo "wolfi-rc already cloned"
        return 0
    fi
    mkdir -p "$TARGET_DIR"
    git clone git@github.com:chainguard-dev/wolfi-rc.git "$TARGET_DIR/main"
}

install_chainctl
install_cg_tokens
install_wolfi_rc
