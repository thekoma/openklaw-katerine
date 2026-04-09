FROM golang:1.26-alpine AS gobuilder

WORKDIR /go
ENV CGO_ENABLED=0
RUN apk add --no-cache git make bash
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@latest
RUN go install github.com/steipete/camsnap/cmd/camsnap@latest
RUN go install github.com/steipete/goplaces/cmd/goplaces@latest
RUN go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest
RUN git clone https://github.com/steipete/gogcli.git
RUN sed -i 's/givenSet bool, given, familySet bool/givenSet bool, given string, familySet bool/' gogcli/internal/cmd/contacts_crud.go
RUN sed -i 's/orgSet bool, org, titleSet bool/orgSet bool, org string, titleSet bool/' gogcli/internal/cmd/contacts_crud.go
RUN cd gogcli && make
RUN cp gogcli/bin/gog /go/bin/gog
RUN git clone https://github.com/hashicorp/vault-mcp-server.git
RUN cd vault-mcp-server && make build
RUN cp vault-mcp-server/bin/vault-mcp-server /go/bin/vault-mcp-server
RUN echo -e "##################\nBuilded go executables\n##################\n"; ls -altr /go/bin; echo -e "##################\n"

FROM ghcr.io/openclaw/openclaw:2026.4.7-1 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/bin"
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm add -g clawhub mcporter @google/gemini-cli better-sqlite3 lancedb @mem0/openclaw-mem0 @googleworkspace/cli@0.22.4 acpx && gws --version
ENV SYSTEM_PACKAGES="ffmpeg pipx mosh jq yq wget git vim ncdu ripgrep sqlite3 tmux iproute2 lsof procps gh vault kubectl"
RUN apt-get update && \
    apt-get install -yq --no-install-recommends wget gnupg lsb-release curl ca-certificates && \
    ARCH=$(dpkg --print-architecture) && \
    CODENAME=$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) && \
    mkdir -p -m 755 /etc/apt/keyrings && \
    add_repo() { \
    local url="$1" \
    keyring="$2" \
    list="$3" \
    entry="$4"; \
    wget -nv -O- "$url" | gpg --dearmor -o "$keyring"; \
    chmod go+r "$keyring"; \
    echo "$entry" | tee "$list" > /dev/null; \
    } && \
    add_repo "https://apt.releases.hashicorp.com/gpg" \
    "/usr/share/keyrings/hashicorp-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/hashicorp.list" \
    "deb [arch=$ARCH signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" && \
    add_repo "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "/etc/apt/keyrings/githubcli-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/github-cli.list" \
    "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" && \
    add_repo "https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key" \
    "/usr/share/keyrings/kubernetes-archive-keyring.gpg" \
    "/etc/apt/sources.list.d/kubernetes.list" \
    "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" && \
    apt-get update && \
    apt-get install -yq --no-install-recommends $SYSTEM_PACKAGES && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIP_NO_CACHE_DIR=1
RUN pipx install uv && \
    rm -rf /root/.cache

# CLI tools: argocd, helm, egctl
RUN ARCH=$(dpkg --print-architecture) && \
    ARGOCD_VERSION=$(curl -sL https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -sL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd && \
    chmod +x /usr/local/bin/argocd && \
    curl -sL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    EGCTL_VERSION=$(curl -sL https://api.github.com/repos/envoyproxy/gateway/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -sL "https://github.com/envoyproxy/gateway/releases/download/${EGCTL_VERSION}/egctl_${EGCTL_VERSION}_linux_${ARCH}.tar.gz" | tar xz -C /usr/local/bin egctl && \
    chmod +x /usr/local/bin/egctl

COPY --from=gobuilder /go/bin/ /usr/local/bin/
USER node
