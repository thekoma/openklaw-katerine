---
name: vault
description: Interact with HashiCorp Vault using Kubernetes authentication to retrieve secrets.
metadata:
  {
    "openclaw":
      {
        "emoji": "🔐",
        "requires": { "bins": ["curl", "jq"] },
      },
  }
---

# Vault Skill

Use this skill to retrieve secrets from the cluster's HashiCorp Vault.

**Note**: This skill uses the environment variables `VAULT_ADDR` and `VAULT_ROLE` for authentication.

## Usage

### vault_get_secret
Retrieve all data from a specific secret path.
- `vault_get_secret path="secret/data/openclaw"`

### vault_get_key
Retrieve a specific key from a secret path.
- `vault_get_key path="secret/data/openclaw" key="SUPERSECRET"`
