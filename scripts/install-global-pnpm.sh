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

# Packages whose postinstall scripts MUST run (otherwise binaries are broken
# even after a successful install). pnpm 10+ refuses to run lifecycle scripts
# unless explicitly allowed.
ALLOW_BUILDS=(
    "@anthropic-ai/claude-code"
)

ALLOW_BUILD_ARGS=()
for pkg in "${ALLOW_BUILDS[@]}"; do
    ALLOW_BUILD_ARGS+=("--allow-build=$pkg")
done

mkdir -p "$PNPM_HOME/bin"
pnpm add -g "${ALLOW_BUILD_ARGS[@]}" "${PACKAGES[@]}"
