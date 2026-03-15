#!/usr/bin/env bash
set -euo pipefail

# Declarative GNOME configuration.
# Using run_onchange_ so this re-applies whenever the script is modified.

cat << EOF | dconf load /
[org/gnome/mutter]
dynamic-workspaces=false
workspaces-only-on-primary=false

[org/gnome/desktop/wm/preferences]
num-workspaces=9

[org/gnome/shell/app-switcher]
current-workspace-only=true
[org/gnome/shell/extensions/dash-to-dock]
isolate-workspaces=true
[org/gnome/shell/extensions/tiling-assistant]
tiling-popup-all-workspace=false

EOF

# dconf resets keyboard repeat delay to 500ms, so use gsettings
gsettings set org.gnome.desktop.peripherals.keyboard delay 200

# Disable quick-settings binding so it doesn't conflict with sublime shortcut
dconf write /org/gnome/shell/keybindings/toggle-quick-settings "@as []"

# ============================================================================
# GNOME WM keybindings for workspace and monitor navigation.
# Pairs with pop-shell config (which handles window focus via Super+Arrow).
# ============================================================================

wm="org.gnome.desktop.wm.keybindings"
mutter="org.gnome.mutter.keybindings"

# Clear defaults that conflict with pop-shell focus (Super+Arrow)
gsettings set "$wm"    maximize            "['']"
gsettings set "$wm"    unmaximize          "['']"
gsettings set "$mutter" toggle-tiled-left   "['']"
gsettings set "$mutter" toggle-tiled-right  "['']"

# Clear Super+N app-switching defaults to free them for workspace jump
shell_kb="org.gnome.shell.keybindings"
for i in $(seq 1 9); do
    gsettings set "$shell_kb" "switch-to-application-$i" "['']"
done

# Clear dash-to-dock hotkeys if available
dock="org.gnome.shell.extensions.dash-to-dock"
if gsettings list-keys "$dock" &>/dev/null; then
    for i in $(seq 1 9); do
        gsettings set "$dock" "app-hotkey-$i" "['']"
    done
    gsettings set "$dock" app-hotkey-10 "['']"
fi

# Workspace switching: Super+PageUp/PageDown
gsettings set "$wm" switch-to-workspace-left  "['<Super>Page_Up']"
gsettings set "$wm" switch-to-workspace-right "['<Super>Page_Down']"

# Move window to adjacent workspace: Super+Shift+PageUp/PageDown
gsettings set "$wm" move-to-workspace-left  "['<Super><Shift>Page_Up']"
gsettings set "$wm" move-to-workspace-right "['<Super><Shift>Page_Down']"

# Disable GNOME move-to-monitor (pop-shell handles this)
gsettings set "$wm" move-to-monitor-left  "['']"
gsettings set "$wm" move-to-monitor-right "['']"
gsettings set "$wm" move-to-monitor-up    "['']"
gsettings set "$wm" move-to-monitor-down  "['']"

# Absolute workspace jump: Super+1-9, Super+0 for workspace 10
for i in $(seq 1 9); do
    gsettings set "$wm" "switch-to-workspace-$i" "['<Super>$i']"
done
gsettings set "$wm" switch-to-workspace-10 "['<Super>0']"

# Move window to specific workspace: Super+Shift+1-9, Super+Shift+0 for ws 10
for i in $(seq 1 9); do
    gsettings set "$wm" "move-to-workspace-$i" "['<Super><Shift>$i']"
done
gsettings set "$wm" move-to-workspace-10 "['<Super><Shift>0']"

echo "GNOME configuration applied."
