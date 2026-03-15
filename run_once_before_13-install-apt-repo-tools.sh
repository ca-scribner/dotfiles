#!/bin/bash
set -euo pipefail

# Tools that require adding a third-party apt repository before installation.
# Each function is independent — a failure in one won't block the others.

install_ghcli() {
    if command -v gh &>/dev/null; then
        echo "gh already installed"
        return 0
    fi
    # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y

    echo ""
    echo "NOTE: Run 'gh auth login -p ssh' manually to authenticate with GitHub"
    echo "NOTE: Run 'ssh-keygen -t ed25519-sk' manually to create an SSH key"
}

install_gcloud() {
    if command -v gcloud &>/dev/null; then
        echo "gcloud already installed"
        return 0
    fi
    # https://cloud.google.com/sdk/docs/install
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update && sudo apt-get install -y google-cloud-cli
}

install_terraform() {
    if command -v terraform &>/dev/null; then
        echo "terraform already installed"
        return 0
    fi
    # https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
    sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update
    sudo apt-get install -y terraform
}

install_sublime() {
    if command -v subl &>/dev/null; then
        echo "sublime already installed"
        return 0
    fi
    # https://www.sublimetext.com/docs/linux_repositories.html
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null
    echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources
    sudo apt-get update
    sudo apt-get install -y sublime-text
}

install_dconf_editor() {
    if command -v dconf-editor &>/dev/null; then
        echo "dconf-editor already installed"
        return 0
    fi
    sudo add-apt-repository -y universe
    sudo apt-get update
    sudo apt-get install -y dconf-cli dconf-editor
}

install_gnome_browser_connector() {
    if dpkg -s gnome-browser-connector &>/dev/null; then
        echo "gnome-browser-connector already installed"
        return 0
    fi
    sudo apt-get install -y gnome-browser-connector
}

install_ghcli
install_gcloud
install_terraform
install_sublime
install_dconf_editor
install_gnome_browser_connector
