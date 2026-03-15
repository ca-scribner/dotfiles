#!/bin/bash
set -euo pipefail

# 32GB swap file — takes about a minute to allocate
if [ -f /swapfile ] && swapon --show | grep -q /swapfile; then
    echo "Swap already configured"
    exit 0
fi

sudo swapoff -a 2>/dev/null || true
sudo dd if=/dev/zero of=/swapfile bs=1G count=32
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "32GB swap file created and enabled"
