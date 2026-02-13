# Cloud-Native Semantic Memory for Karoline

This directory contains Kubernetes manifests for deploying ChromaDB as the semantic memory store for Karoline.

## Architecture

- **ChromaDB**: Deployed as a persistent service in the cluster (`clawrag` namespace).
- **Embeddings**: Generated using Google Gemini (client-side).
- **Inference**: Handled externally or by other components (not in this cluster deployment).

## Deployment

1. Create the namespace:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. Apply ChromaDB manifests:
   ```bash
   kubectl apply -f chromadb.yaml
   ```

3. (Optional) Configure Ingress for external access:
   Edit `ingress.yaml` with your domain and TLS settings, then apply:
   ```bash
   kubectl apply -f ingress.yaml
   ```

## Karoline Configuration

To configure Karoline to use this setup, update your agent configuration (e.g., `config.yaml` or environment variables):

### 1. Embedding Provider (Gemini)
Karoline should use Google Gemini for generating embeddings. Ensure you have a valid API key.

```yaml
memory:
  embedding_provider: "google_gemini"
  google_api_key: "${GOOGLE_API_KEY}" # Set this env var
  model: "models/embedding-001" # Or preferred model
```

### 2. Vector Store (ChromaDB)
Point Karoline to the ChromaDB service.

**Internal Access (if Karoline runs in the same cluster):**
- **Host**: `chroma.clawrag.svc.cluster.local`
- **Port**: `8000`
- **Auth**: If enabled, provide the token via `CHROMA_SERVER_AUTH_TOKEN`.

**External Access (if Karoline runs outside):**
- **Host**: `https://chroma.example.com` (Your Ingress domain)
- **Port**: `443`
- **Auth**: Required for secure access over public internet.

### Example Config Snippet

```yaml
memory:
  type: "chromadb"
  chroma_url: "http://chroma.clawrag.svc.cluster.local:8000"
  collection_name: "karoline_memory"
  embedding_function:
    provider: "google_gemini"
    api_key_env: "GOOGLE_API_KEY"
```

## Security Note
This deployment uses basic settings. For production:
- Enable authentication on ChromaDB.
- Use NetworkPolicies to restrict access.
- Ensure PVC storage class supports expansion/backup.
