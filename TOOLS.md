# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

### MCP Servers

- **kubernetes**: Stdio via `npx -y mcp-server-kubernetes`. Used for cluster resource management.
- **github**: Stdio via `npx -y @modelcontextprotocol/server-github`. Uses `GITHUB_TOKEN` from env.
- **context7**: Stdio via `npx -y @upstash/context7-mcp`. Uses `CONTEXT7_API_KEY` from env.
- **grafana**: Stdio via `npx -y @leval/mcp-grafana`.
  - URL: `http://kube-prometheus-stack-grafana.prometheus.svc.cluster.local`
  - Auth: JWT using pod token (`/var/run/secrets/kubernetes.io/serviceaccount/token`).
- **hass**: HTTP via `http://192.168.85.8:8123/api/mcp`.
  - Auth: Long-lived access token.
- **vikunja**: Stdio via `npx -y @0xk3vin/vikunja-mcp`.
  - Env: `VIKUNJA_URL` and `VIKUNJA_API_TOKEN` (from Vault path `secret/data/openclaw`).

### Monitoring & Analytics

- **Grafana Image Renderer**: Standalone service at `http://kube-prometheus-stack-grafana-image-renderer.prometheus:8081/render`.
- **Render URL Pattern**: `http://kube-prometheus-stack-grafana.prometheus.svc.cluster.local/render/d-solo/<uid>/_?orgId=1&panelId=<id>&var-node=<node>&var-cluster=&width=1000&height=500`.
- **Dashboards**:
  - Node Exporter: `7d57716318ee0dddbac5a7f451fb7753`
  - K8s Resources: `200ac8fdbfbb74b39aff88118e4d1c2c`
