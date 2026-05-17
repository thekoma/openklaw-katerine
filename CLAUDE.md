# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A thin customisation layer on top of `ghcr.io/openclaw/openclaw`. The
output is a single multi-arch container image (`ghcr.io/thekoma/openclaw-koma`)
built and pushed by GitHub Actions on every push to `main`, on every git tag,
and nightly at 03:00 UTC. There is no application source code here — the only
build artifact is the image.

## Architecture

The whole pipeline lives in three places:

- **`Dockerfile`** — two-stage build.
  - Stage `gobuilder` (alpine + Go 1.26): compiles a handful of Go MCP servers /
    CLI tools (`gifgrep`, `camsnap`, `goplaces`, `mcp-grafana`, `gogcli`,
    `vault-mcp-server`) into `/go/bin`.
  - Stage `openclaw` (FROM `ghcr.io/openclaw/openclaw:<tag>`): installs global
    pnpm packages, third-party APT repos + system packages, `mempalace` via
    pipx, three pinned CLI tools (argocd / helm / egctl), and finally copies
    the Go binaries from `gobuilder`. Last instruction is `USER node`.
- **`scripts/install-*.sh`** — every non-trivial install step is here. Each
  script is `COPY`ed immediately before its `RUN` so editing it invalidates
  only that layer (and the layers after). Edit these scripts to change the
  package list, not the Dockerfile.
- **`.github/workflows/release.yaml`** — builds, pushes to GHCR, calculates
  the next CalVer tag (`YYYY.MM.N`, auto-incremented from the latest existing
  tag of the same `YYYY.MM`), pushes the git tag on success, and creates a
  GitHub release. Triggered by push / tag / schedule.

### Version pinning convention

Every pinned tool in `Dockerfile` is an `ARG` preceded by a magic comment:

```dockerfile
# renovate: datasource=<datasource> depName=<owner/repo>
ARG TOOL_VERSION=v1.2.3
```

A single regex `customManagers` block in `renovate.json` picks them all up,
so Renovate opens a bump PR for each tool the same way it does for the base
image. Use `endoflife-date` (`depName=kubernetes`) for the Kubernetes APT
repo minor — that one is explicitly NOT auto-merged because it bumps the
kubectl version. Everything else minor/patch is auto-merged by the existing
`packageRules`.

When adding a new pinned tool: add the annotated `ARG`, reference it in the
Dockerfile or the relevant script, and the regex picks it up — no change to
`renovate.json` needed unless you want a custom rule (e.g. disable
automerge).

## Common commands

This repo is built in CI; local builds are usually unnecessary and crash
on Apple Silicon (see pitfalls). The commands you'll actually use:

```bash
# Watch / debug the build pipeline
gh run list --workflow=release.yaml --limit 10
gh run view <run-id> --log-failed | tail -200

# Manually trigger a build
gh workflow run release.yaml

# Inspect the upstream base image (debug pnpm / corepack issues etc.)
docker run --rm --user root --entrypoint sh ghcr.io/openclaw/openclaw:<tag> -c '<command>'

# Test a single install script against the real base image
docker run --rm --user root \
  -v "$(pwd)/scripts:/scripts:ro" \
  -e ARGOCD_VERSION=v3.4.2 -e HELM_VERSION=v4.2.0 -e EGCTL_VERSION=v1.8.0 \
  ghcr.io/openclaw/openclaw:<tag> /scripts/install-clitools.sh

# Validate the Renovate customManager regex without pushing
python3 -c "
import re
text = open('Dockerfile').read()
pattern = r'# renovate: datasource=(?P<datasource>\S+) depName=(?P<depName>\S+)(?:\s+versioning=(?P<versioning>\S+))?\s+ARG \w+=(?P<currentValue>[\w.+-]+)'
for m in re.finditer(pattern, text):
    print(m.groupdict())
"
```

## Pitfalls

- **pnpm ≥ 10 changed the global bin dir**: it is now `$PNPM_HOME/bin`, not
  `$PNPM_HOME`. The repo intentionally sets `PNPM_HOME=/usr/local/share/pnpm`
  and adds `$PNPM_HOME/bin` to `PATH`. Do NOT point `PNPM_HOME` at a system
  bin directory like `/usr/local/bin` — pnpm will try to install into
  `/usr/local/bin/bin` and fail with "configured global bin directory ... is
  not in PATH".

- **Local `docker build` on Apple Silicon will crash** in the `gobuilder`
  stage with a `runtime error: invalid memory address or nil pointer
  dereference` in `cmd/go/internal/modindex` — this is a Go-under-QEMU bug,
  not a Dockerfile bug. Test changes on the GitHub runner (native amd64)
  instead, or build the `openclaw` stage alone using a prebuilt
  `gobuilder` image. Individual install scripts can still be exercised
  locally as shown above.

- **Cache locality**: each `scripts/install-*.sh` is `COPY`ed right before
  its `RUN`. Preserving this pattern matters — putting one big
  `COPY scripts/ /tmp/scripts/` at the top would cause every script edit to
  invalidate every downstream layer.

- **`SBOM` / `provenance` / `outputs:`** — the `docker/build-push-action`
  input is `outputs` (plural). A `output` typo silently degrades to "no
  output configured" and was the cause of a prior failure.
