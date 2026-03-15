#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/src"

install_eza() {
    if command -v eza &>/dev/null; then
        echo "eza already installed"
        return 0
    fi
    sudo apt-get update
    sudo apt-get install -y eza

    # Zsh completions — .zshrc sets FPATH="$HOME/.local/src/completions/zsh:$FPATH"
    if [ ! -d "$HOME/.local/src/eza" ]; then
        git clone https://github.com/eza-community/eza.git "$HOME/.local/src/eza"
    fi
    # Symlink so completions land at the FPATH location .zshrc expects
    mkdir -p "$HOME/.local/src/completions"
    ln -sfn "$HOME/.local/src/eza/completions/zsh" "$HOME/.local/src/completions/zsh"
}

install_fd() {
    if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
        echo "fd already installed"
        # Ensure the symlink exists even if fd-find is already installed
        if command -v fdfind &>/dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
            ln -s "$(which fdfind)" "$HOME/.local/bin/fd"
        fi
        return 0
    fi
    # https://github.com/sharkdp/fd
    sudo apt-get install -y fd-find
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
}

install_git_fuzzy() {
    if command -v git-fuzzy &>/dev/null; then
        echo "git-fuzzy already installed"
        return 0
    fi
    # https://github.com/bigH/git-fuzzy
    if [ ! -d "$HOME/.local/src/git-fuzzy" ]; then
        git clone https://github.com/bigH/git-fuzzy.git "$HOME/.local/src/git-fuzzy"
    fi
    ln -sf "$HOME/.local/src/git-fuzzy/bin/git-fuzzy" "$HOME/.local/bin/git-fuzzy"
}

install_obsidian() {
    if snap list obsidian &>/dev/null; then
        echo "obsidian already installed"
        return 0
    fi
    sudo snap install obsidian --classic

    # Work around snap Chrome profile isolation
    if [ -d "$HOME/snap/obsidian/current/.config/google-chrome" ]; then
        sudo rm -rf "$HOME/snap/obsidian/current/.config/google-chrome"
    fi
    if [ -d "$HOME/.config/google-chrome" ]; then
        ln -sf "$HOME/.config/google-chrome" "$HOME/snap/obsidian/current/.config/google-chrome"
    fi
}

install_eza
install_fd
install_git_fuzzy
install_obsidian
