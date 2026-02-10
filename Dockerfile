FROM golang:1.25-alpine AS gobuilder

WORKDIR /go
ENV CGO_ENABLED=0
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@latest && \
    go install github.com/steipete/camsnap/cmd/camsnap@latest


FROM ghcr.io/openclaw/openclaw:2026.2.9 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/bin"
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm add -g clawhub mcporter @google/gemini-cli
ENV SYSTEM_PACKAGES="ffmpeg mosh jq sudo wget vim ncdu ripgrep tmux iproute2 lsof procps gh"
RUN apt update && \
    apt install -yq $SYSTEM_PACKAGES && \
    mkdir -p -m 755 /etc/apt/keyrings && \
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    mkdir -p -m 755 /etc/apt/sources.list.d && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && apt install -yq gh && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/* && \
    echo 'node ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/00-node
USER node    
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) >> /home/node/.bashrc && \
    brew install steipete/tap/gogcli
COPY --from=gobuilder /go/bin/gifgrep /usr/local/bin/gifgrep
COPY --from=gobuilder /go/bin/camsnap /usr/local/bin/camsnap
USER node
