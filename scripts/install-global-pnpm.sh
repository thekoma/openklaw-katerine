#!/usr/bin/env bash
# Install pnpm global packages into $PNPM_HOME/bin (see Dockerfile).
# Edit this list to add/remove tools — changes invalidate only this layer.
set -euo pipefail

: "${PNPM_HOME:?PNPM_HOME is required}"

PACKAGES=(
    "@anthropic-ai/claude-code"
    "@google/gemini-cli"
    acpx
    better-sqlite3
    clawhub
    mcporter
)

mkdir -p "$PNPM_HOME/bin"
pnpm add -g "${PACKAGES[@]}"
