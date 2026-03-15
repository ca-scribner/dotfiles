#!/bin/bash
set -euo pipefail

# # Snaps that need --classic
# for pkg in SOMETHING; do
#     if ! snap list "$pkg" &>/dev/null; then
#         sudo snap install "$pkg" --classic
#     fi
# done

# Standard snaps
for pkg in fx slack ticktick; do
    if ! snap list "$pkg" &>/dev/null; then
        sudo snap install "$pkg"
    fi
done
