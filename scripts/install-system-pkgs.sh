#!/usr/bin/env bash
# Install the runtime system packages. Edit this list to add/remove tools —
# changes to this file invalidate only this layer's cache.
set -euo pipefail

PACKAGES=(
    ffmpeg
    gh
    git
    iproute2
    jq
    kubectl
    lsof
    mosh
    ncdu
    pipx
    procps
    ripgrep
    sqlite3
    tmux
    vault
    vim
    wget
    wkhtmltopdf
    yq
)

apt-get install -yq --no-install-recommends "${PACKAGES[@]}"
rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
