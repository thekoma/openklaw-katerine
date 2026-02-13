#!/bin/bash
# vault.sh - implementation for Vault skill using Kubernetes Auth

TOKEN_PATH="/var/run/secrets/kubernetes.io/serviceaccount/token"

if [ -z "$VAULT_ADDR" ]; then
    echo "Error: VAULT_ADDR is not set."
    exit 1
fi

if [ -z "$VAULT_ROLE" ]; then
    # Fallback to a default if not provided, but the user said they will set it
    VAULT_ROLE="openclaw-role"
fi

function get_vault_token() {
    local jwt=$(cat "$TOKEN_PATH")
    local response=$(curl -k -s -X POST "$VAULT_ADDR/v1/auth/kubernetes/login" \
        -d "{\"role\": \"$VAULT_ROLE\", \"jwt\": \"$jwt\"}")
    echo "$response" | jq -r .auth.client_token
}

case "$1" in
    vault_get_secret)
        VT=$(get_vault_token)
        if [ "$VT" == "null" ]; then echo "Error: Authentication failed."; exit 1; fi
        curl -k -s -H "X-Vault-Token: $VT" "$VAULT_ADDR/v1/$path" | jq .data.data
        ;;
    vault_get_key)
        VT=$(get_vault_token)
        if [ "$VT" == "null" ]; then echo "Error: Authentication failed."; exit 1; fi
        curl -k -s -H "X-Vault-Token: $VT" "$VAULT_ADDR/v1/$path" | jq -r ".data.data.\"$key\""
        ;;
esac
