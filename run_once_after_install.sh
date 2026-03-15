#!/bin/bash
set -euo pipefail

# Bootstrap just and run the full install.
# chezmoi places ~/.justfile before this script runs,
# so we just need just itself.

if ! command -v just &>/dev/null; then
    echo "Installing just..."
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
fi

just --justfile "$HOME/.justfile" install-all
