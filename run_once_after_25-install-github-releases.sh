#!/bin/bash
set -euo pipefail

# Tools installed by downloading from GitHub releases.
# Uses get_latest_github_release.sh (placed by chezmoi) where possible,
# with inline logic for tools that need special handling (.deb, specific assets).

mkdir -p "$HOME/.local/bin"

install_fzf() {
    if command -v fzf &>/dev/null; then
        echo "fzf already installed"
        return 0
    fi
    # https://github.com/junegunn/fzf
    get_latest_github_release.sh junegunn/fzf fzf
}

install_lazygit() {
    if command -v lazygit &>/dev/null; then
        echo "lazygit already installed"
        return 0
    fi
    # https://github.com/jesseduffield/lazygit
    get_latest_github_release.sh jesseduffield/lazygit lazygit
}

install_cosign() {
    if command -v cosign &>/dev/null; then
        echo "cosign already installed"
        return 0
    fi
    # https://github.com/sigstore/cosign
    LATEST_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
    TEMP_DEB=$(mktemp --suffix=.deb)
    curl -fsSL -o "$TEMP_DEB" "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb"
    sudo dpkg -i "$TEMP_DEB"
    rm "$TEMP_DEB"
}

install_delta() {
    if command -v delta &>/dev/null; then
        echo "delta already installed"
        return 0
    fi
    # https://github.com/dandavison/delta
    TEMP_DEB=$(mktemp --suffix=.deb)
    curl -fsSL https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_amd64.deb -o "$TEMP_DEB"
    sudo dpkg -i "$TEMP_DEB"
    rm "$TEMP_DEB"
}

install_diff_so_fancy() {
    if command -v diff-so-fancy &>/dev/null; then
        echo "diff-so-fancy already installed"
        return 0
    fi
    # https://github.com/so-fancy/diff-so-fancy
    curl -fsSL https://github.com/so-fancy/diff-so-fancy/releases/download/v1.4.4/diff-so-fancy -o "$HOME/.local/bin/diff-so-fancy"
    chmod +x "$HOME/.local/bin/diff-so-fancy"
}

install_hugo() {
    if command -v hugo &>/dev/null; then
        echo "hugo already installed"
        return 0
    fi
    # https://gohugo.io/installation/linux/
    TEMP_DIR=$(mktemp -d)
    curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
      | grep -e "browser_download_url.*hugo_extended_[0-9].*_linux-amd64.tar.gz" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | wget -q -i - -O - \
      | tar xz -C "$TEMP_DIR" && mv "$TEMP_DIR/hugo" "$HOME/.local/bin/hugo"
    rm -rf "$TEMP_DIR"
}

install_yq() {
    if command -v yq &>/dev/null; then
        echo "yq already installed"
        return 0
    fi
    # https://github.com/mikefarah/yq
    curl -s https://api.github.com/repos/mikefarah/yq/releases/latest \
      | grep "browser_download_url.*yq_linux_amd64.tar.gz" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | wget -q -i - -O - \
      | tar xz && mv yq_linux_amd64 "$HOME/.local/bin/yq"
}

install_kubectl() {
    if command -v kubectl &>/dev/null; then
        echo "kubectl already installed"
        return 0
    fi
    # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
    TEMP_FILE=$(mktemp)
    curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o "$TEMP_FILE"
    sudo install -o root -g root -m 0755 "$TEMP_FILE" /usr/local/bin/kubectl
    rm "$TEMP_FILE"
}

install_jetbrains_toolbox() {
    if command -v jetbrains-toolbox &>/dev/null; then
        echo "jetbrains-toolbox already installed"
        return 0
    fi
    VERSION="3.0.1.59888"
    TEMP_DIR=$(mktemp -d)
    wget "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz" -O "$TEMP_DIR/jetbrains-toolbox.tar.gz"
    tar -xzf "$TEMP_DIR/jetbrains-toolbox.tar.gz" -C "$TEMP_DIR"
    mv "$TEMP_DIR"/jetbrains-toolbox-*/jetbrains-toolbox "$HOME/.local/bin/"
    rm -rf "$TEMP_DIR"
}

install_fzf
install_lazygit
install_cosign
install_delta
install_diff_so_fancy
install_hugo
install_yq
install_kubectl
install_jetbrains_toolbox
