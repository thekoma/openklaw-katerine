FROM golang:1.25-alpine AS gobuilder

WORKDIR /go
ENV CGO_ENABLED=0
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@latest
RUN go install github.com/steipete/camsnap/cmd/camsnap@latest
RUN apk add --no-cache git make bash && \
    git clone https://github.com/steipete/gogcli.git && \
    cd gogcli && \
    make && \
    cp bin/gog /go/bin/gogcli

FROM ghcr.io/openclaw/openclaw:2026.2.9 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/bin"
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm add -g clawhub mcporter @google/gemini-cli
ENV SYSTEM_PACKAGES="ffmpeg mosh jq wget vim ncdu ripgrep tmux iproute2 lsof procps gh"
RUN apt update && \
    apt install -yq --no-install-recommends $SYSTEM_PACKAGES && \
    mkdir -p -m 755 /etc/apt/keyrings && \
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    mkdir -p -m 755 /etc/apt/sources.list.d && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && apt install -yq --no-install-recommends gh && \
    rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
COPY --from=gobuilder /go/bin/gifgrep /go/bin/camsnap /go/bin/gogcli /usr/local/bin/
USER node
