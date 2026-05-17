#!/usr/bin/env bash
# Register third-party APT keyrings + sources used by install-system-pkgs.sh.
set -euo pipefail

: "${K8S_APT_MINOR:?K8S_APT_MINOR is required (e.g. 1.35)}"

apt-get update
apt-get install -yq --no-install-recommends \
    wget gnupg lsb-release curl ca-certificates

ARCH=$(dpkg --print-architecture)
CODENAME=$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs)

mkdir -p -m 755 /etc/apt/keyrings

add_repo() {
    local url="$1" keyring="$2" list="$3" entry="$4"
    wget -nv -O- "$url" | gpg --dearmor -o "$keyring"
    chmod go+r "$keyring"
    echo "$entry" > "$list"
}

add_repo \
    "https://apt.releases.hashicorp.com/gpg" \
    "/usr/share/keyrings/hashicorp-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/hashicorp.list" \
    "deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main"

add_repo \
    "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "/etc/apt/keyrings/githubcli-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/github-cli.list" \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"

add_repo \
    "https://pkgs.k8s.io/core:/stable:/v${K8S_APT_MINOR}/deb/Release.key" \
    "/usr/share/keyrings/kubernetes-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/kubernetes.list" \
    "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_APT_MINOR}/deb/ /"

apt-get update
