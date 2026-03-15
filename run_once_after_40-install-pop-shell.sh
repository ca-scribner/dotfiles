#!/bin/bash
set -euo pipefail

# https://github.com/pop-os/shell
# Dependencies: nodejs, npm, typescript (installed in apt-packages and npm steps)

INSTALL_DIR="$HOME/.local/src/pop-shell"

if [ -d "$HOME/.local/share/gnome-shell/extensions/pop-shell@system76.com" ]; then
    echo "pop-shell already installed"
    exit 0
fi

if ! command -v npm &>/dev/null; then
    echo "ERROR: npm required for pop-shell — skipping"
    exit 1
fi

# Ensure typescript is available
if ! command -v tsc &>/dev/null; then
    sudo npm install -g typescript
fi

mkdir -p "$HOME/.local/src"
if [ ! -d "$INSTALL_DIR" ]; then
    git clone https://github.com/pop-os/shell.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
git checkout master_noble
make local-install

echo ""
echo "NOTE: Log out and back in, then run:"
echo "  gnome-extensions enable 'pop-shell@system76.com'"

# Configure Pop Shell keybindings
export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/pop-shell@system76.com/schemas"
pop="org.gnome.shell.extensions.pop-shell"

gs() { gsettings set "$pop" "$@"; }

# Window focus: Super+Arrow
gs focus-left  "['<Super>Left']"
gs focus-right "['<Super>Right']"
gs focus-up    "['<Super>Up']"
gs focus-down  "['<Super>Down']"

# Clear bindings that conflict with other keybindings
gs search            "['']"
gs activate-launcher "['']"
gs tile-enter        "['']"
gs toggle-floating   "['']"

gs tile-swap-left  "['']"
gs tile-swap-right "['']"
gs tile-swap-up    "['']"
gs tile-swap-down  "['']"

gs tile-resize-left  "['']"
gs tile-resize-right "['']"
gs tile-resize-up    "['']"
gs tile-resize-down  "['']"

gs show-skip-taskbar "['']"

# Use GNOME WM bindings for workspaces, pop-shell for monitor movement
gs pop-workspace-left  "['']"
gs pop-workspace-right "['']"
gs pop-workspace-up    "['']"
gs pop-workspace-down  "['']"
gs pop-monitor-left    "['<Super><Ctrl>Left']"
gs pop-monitor-right   "['<Super><Ctrl>Right']"
gs pop-monitor-up      "['<Super><Ctrl>Up']"
gs pop-monitor-down    "['<Super><Ctrl>Down']"
