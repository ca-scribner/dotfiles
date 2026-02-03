#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <owner/repo> [binary_name]"
    echo "Example: $0 jesseduffield/lazygit"
    echo "Example: $0 jesseduffield/lazygit lazygit"
    exit 1
fi

REPO="$1"
BINARY_NAME="$2"

# Create temporary directory
WORK_DIR=$(mktemp -d -t "install-release-XXXXXX")
trap "rm -rf '$WORK_DIR'" EXIT

cd "$WORK_DIR"

# Get latest release info
RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

# Get version
VERSION=$(echo "$RELEASE_JSON" | \grep -Po '"tag_name": *"\K[^"]*')

if [ -z "$VERSION" ]; then
    echo "Error: Could not fetch latest version for ${REPO}"
    exit 1
fi

echo "Latest version: ${VERSION}"

# Find Linux AMD64 asset
ASSET_URL=$(echo "$RELEASE_JSON" | \grep -Po '"browser_download_url": *"\K[^"]*' | \grep -i 'linux' | \grep -i -E 'amd64|x86_64|x64' | head -n 1)

if [ -z "$ASSET_URL" ]; then
    echo "Error: No Linux AMD64 asset found for ${REPO}"
    echo "Available assets:"
    echo "$RELEASE_JSON" | \grep -Po '"browser_download_url": *"\K[^"]*'
    exit 1
fi

# Determine download filename
DOWNLOAD_NAME=$(basename "$ASSET_URL")

echo "Downloading: $ASSET_URL"
curl -Lo "$DOWNLOAD_NAME" "$ASSET_URL"

# Decompress if needed
case "$DOWNLOAD_NAME" in
    *.tar.gz|*.tgz)
        echo "Extracting tar.gz archive..."
        tar xzf "$DOWNLOAD_NAME"
        ;;
    *.tar.bz2|*.tbz2)
        echo "Extracting tar.bz2 archive..."
        tar xjf "$DOWNLOAD_NAME"
        ;;
    *.tar.xz|*.txz)
        echo "Extracting tar.xz archive..."
        tar xJf "$DOWNLOAD_NAME"
        ;;
    *.zip)
        echo "Extracting zip archive..."
        unzip -q "$DOWNLOAD_NAME"
        ;;
    *.gz)
        echo "Decompressing gzip file..."
        gunzip "$DOWNLOAD_NAME"
        ;;
    *.bz2)
        echo "Decompressing bzip2 file..."
        bunzip2 "$DOWNLOAD_NAME"
        ;;
    *.xz)
        echo "Decompressing xz file..."
        unxz "$DOWNLOAD_NAME"
        ;;
esac

# Find the binary to install
if [ -n "$BINARY_NAME" ]; then
    # User specified binary name
    if [ ! -f "$BINARY_NAME" ]; then
        echo "Error: Specified binary '$BINARY_NAME' not found after extraction"
        echo "Available files:"
        ls -1
        exit 1
    fi
    BINARY_TO_INSTALL="$BINARY_NAME"
else
    # Try to find an executable binary
    # First, look for files matching the repo name
    REPO_NAME=$(echo "$REPO" | cut -d'/' -f2)
    
    if [ -f "$REPO_NAME" ] && [ -x "$REPO_NAME" ]; then
        BINARY_TO_INSTALL="$REPO_NAME"
    else
        # Find any executable file
        BINARY_TO_INSTALL=$(find . -maxdepth 1 -type f -executable | head -n 1)
        
        if [ -z "$BINARY_TO_INSTALL" ]; then
            echo "Error: No executable binary found"
            echo "Available files:"
            ls -1
            echo ""
            echo "Please specify the binary name as the second argument"
            exit 1
        fi
        
        BINARY_TO_INSTALL=$(basename "$BINARY_TO_INSTALL")
    fi
fi

echo "Installing $BINARY_TO_INSTALL to $HOME/.local/bin/"

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Install the binary
install -m 755 "$BINARY_TO_INSTALL" "$HOME/.local/bin/"

echo "Successfully installed $BINARY_TO_INSTALL ${VERSION} to $HOME/.local/bin/"
