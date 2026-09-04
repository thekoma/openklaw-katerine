FROM golang:1.27-alpine AS gobuilder

# renovate: datasource=github-releases depName=steipete/gifgrep
ARG GIFGREP_VERSION=v0.3.1
# renovate: datasource=github-releases depName=steipete/camsnap
ARG CAMSNAP_VERSION=v0.5.0
# renovate: datasource=github-releases depName=steipete/goplaces
ARG GOPLACES_VERSION=v0.4.9
# renovate: datasource=github-releases depName=grafana/mcp-grafana
ARG MCP_GRAFANA_VERSION=v1.3.0
# renovate: datasource=github-tags depName=steipete/gogcli
ARG GOGCLI_VERSION=v0.39.0
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

FROM ghcr.io/openclaw/openclaw:2026.9.1 AS openclaw

USER root
ENV PNPM_HOME="/usr/local/share/pnpm"
ENV PATH="$PNPM_HOME/bin:$PATH"
COPY scripts/install-global-pnpm.sh /tmp/scripts/
RUN /tmp/scripts/install-global-pnpm.sh

# renovate: datasource=endoflife-date depName=kubernetes
ARG K8S_APT_MINOR=1.35
COPY scripts/install-apt-repos.sh /tmp/scripts/
RUN K8S_APT_MINOR="$K8S_APT_MINOR" /tmp/scripts/install-apt-repos.sh

COPY scripts/install-system-pkgs.sh /tmp/scripts/
RUN /tmp/scripts/install-system-pkgs.sh

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
ARG ARGOCD_VERSION=v3.5.2
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v4.2.4
# renovate: datasource=github-releases depName=envoyproxy/gateway
ARG EGCTL_VERSION=v1.9.1
COPY scripts/install-clitools.sh /tmp/scripts/
RUN ARGOCD_VERSION="$ARGOCD_VERSION" \
    HELM_VERSION="$HELM_VERSION" \
    EGCTL_VERSION="$EGCTL_VERSION" \
    /tmp/scripts/install-clitools.sh

COPY --from=gobuilder /go/bin/ /usr/local/bin/
USER node
