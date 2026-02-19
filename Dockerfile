FROM golang:1.26-alpine AS gobuilder

WORKDIR /go
ENV CGO_ENABLED=0
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@latest
RUN go install github.com/steipete/camsnap/cmd/camsnap@latest
RUN go install github.com/steipete/goplaces/cmd/goplaces@latest
RUN go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest
RUN apk add --no-cache git make bash && \
    git clone https://github.com/steipete/gogcli.git && \
    cd gogcli && \
    make && \
    cp bin/gog /go/bin/gog
RUN echo -e "##################\nBuilded go executables\n##################\n"; ls -altr /go/bin; echo -e "##################\n"

FROM ghcr.io/openclaw/openclaw:2026.2.17 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/bin"
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm add -g clawhub mcporter @google/gemini-cli better-sqlite3 lancedb @mem0/openclaw-mem0
ENV SYSTEM_PACKAGES="ffmpeg pipx mosh jq wget git vim ncdu ripgrep sqlite3 tmux iproute2 lsof procps gh vault kubectl"
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
COPY --from=gobuilder /go/bin/ /usr/local/bin/
USER node
