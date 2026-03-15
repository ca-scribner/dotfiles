#!/bin/bash
set -euo pipefail

# Go must be on PATH for `go install` to work.
# chezmoi run scripts use bash (not zsh), so .zshrc isn't sourced.
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:$GOPATH/bin"

if ! command -v go &>/dev/null; then
    echo "ERROR: go not found — skipping go tool installs"
    exit 1
fi

install_go_tool() {
    local cmd="$1"
    local pkg="$2"
    if command -v "$cmd" &>/dev/null; then
        echo "$cmd already installed"
        return 0
    fi
    echo "Installing $cmd..."
    go install "$pkg"
}

install_go_tool crane   github.com/google/go-containerregistry/cmd/crane@latest
install_go_tool cue     cuelang.org/go/cmd/cue@latest
install_go_tool dive    github.com/wagoodman/dive@latest
install_go_tool yam     github.com/chainguard-dev/yam@latest
install_go_tool gitsign github.com/sigstore/gitsign@latest
