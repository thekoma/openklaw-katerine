#!/usr/bin/env bash
# Download pinned argocd, helm, egctl release binaries. Versions are passed
# as env vars from the Dockerfile (ARG → ENV → here).
set -euo pipefail

: "${ARGOCD_VERSION:?ARGOCD_VERSION is required}"
: "${HELM_VERSION:?HELM_VERSION is required}"
: "${EGCTL_VERSION:?EGCTL_VERSION is required}"

ARCH=$(dpkg --print-architecture)

curl -fsSL \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" \
    -o /usr/local/bin/argocd
chmod +x /usr/local/bin/argocd

curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" \
    | tar xz --strip-components=1 -C /usr/local/bin "linux-${ARCH}/helm"
chmod +x /usr/local/bin/helm

curl -fsSL \
    "https://github.com/envoyproxy/gateway/releases/download/${EGCTL_VERSION}/egctl_${EGCTL_VERSION}_linux_${ARCH}.tar.gz" \
    | tar xz --strip-components=3 -C /usr/local/bin "bin/linux/${ARCH}/egctl"
chmod +x /usr/local/bin/egctl
