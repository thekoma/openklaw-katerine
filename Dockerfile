FROM golang:1.26-alpine AS gobuilder

# renovate: datasource=github-releases depName=steipete/gifgrep
ARG GIFGREP_VERSION=v0.3.0
# renovate: datasource=github-releases depName=steipete/camsnap
ARG CAMSNAP_VERSION=v0.2.1
# renovate: datasource=github-releases depName=steipete/goplaces
ARG GOPLACES_VERSION=v0.4.2
# renovate: datasource=github-releases depName=grafana/mcp-grafana
ARG MCP_GRAFANA_VERSION=v0.14.0
# renovate: datasource=github-tags depName=steipete/gogcli
ARG GOGCLI_VERSION=v0.17.0
# renovate: datasource=github-releases depName=hashicorp/vault-mcp-server
ARG VAULT_MCP_SERVER_VERSION=v0.2.0

WORKDIR /go
ENV CGO_ENABLED=0
RUN apk add --no-cache git make bash
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@${GIFGREP_VERSION}
RUN go install github.com/steipete/camsnap/cmd/camsnap@${CAMSNAP_VERSION}
RUN go install github.com/steipete/goplaces/cmd/goplaces@${GOPLACES_VERSION}
RUN go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@${MCP_GRAFANA_VERSION}
RUN git clone --depth 1 --branch ${GOGCLI_VERSION} https://github.com/steipete/gogcli.git
RUN cd gogcli && make
RUN cp gogcli/bin/gog /go/bin/gog
RUN git clone --depth 1 --branch ${VAULT_MCP_SERVER_VERSION} https://github.com/hashicorp/vault-mcp-server.git
RUN cd vault-mcp-server && make build
RUN cp vault-mcp-server/bin/vault-mcp-server /go/bin/vault-mcp-server
RUN echo -e "##################\nBuilded go executables\n##################\n"; ls -altr /go/bin; echo -e "##################\n"

FROM ghcr.io/openclaw/openclaw:2026.5.12 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/share/pnpm"
ENV PATH="$PNPM_HOME/bin:$PATH"
RUN mkdir -p "$PNPM_HOME/bin" && \
    pnpm add -g clawhub mcporter @google/gemini-cli better-sqlite3 acpx @anthropic-ai/claude-code
ENV SYSTEM_PACKAGES="ffmpeg pipx mosh jq yq wget git vim ncdu ripgrep sqlite3 tmux iproute2 lsof procps gh vault kubectl wkhtmltopdf"
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
    uv venv /opt/mempalace && \
    uv pip install --python /opt/mempalace/bin/python mempalace && \
    ln -s /opt/mempalace/bin/mempalace /usr/local/bin/mempalace && \
    rm -rf /root/.cache

# CLI tools: argocd, helm, egctl
# renovate: datasource=github-releases depName=argoproj/argo-cd
ARG ARGOCD_VERSION=v3.4.2
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v4.2.0
# renovate: datasource=github-releases depName=envoyproxy/gateway
ARG EGCTL_VERSION=v1.8.0
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd && \
    chmod +x /usr/local/bin/argocd && \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar xz --strip-components=1 -C /usr/local/bin linux-${ARCH}/helm && \
    chmod +x /usr/local/bin/helm && \
    curl -fsSL "https://github.com/envoyproxy/gateway/releases/download/${EGCTL_VERSION}/egctl_${EGCTL_VERSION}_linux_${ARCH}.tar.gz" | tar xz --strip-components=3 -C /usr/local/bin bin/linux/${ARCH}/egctl && \
    chmod +x /usr/local/bin/egctl

COPY --from=gobuilder /go/bin/ /usr/local/bin/
USER node
