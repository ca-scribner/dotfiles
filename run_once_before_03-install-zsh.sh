#!/bin/bash
set -euo pipefail

if command -v zsh &>/dev/null; then
    echo "zsh already installed"
else
    sudo apt install -y zsh
fi

# Set zsh as default shell if it isn't already
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to zsh — log out and back in for it to take effect"
fi
