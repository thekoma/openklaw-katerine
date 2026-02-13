# ClawRAG Kubernetes Deployment

This directory contains the Kubernetes manifests for deploying ClawRAG in the `openclaw` namespace.

## Components

- **ChromaDB**: Vector database for semantic storage.
- **Ollama**: LLM server for embeddings and reasoning (GPU support recommended if available).
- **Backend**: FastAPI service for document ingestion and retrieval.
- **Gateway**: Nginx reverse proxy and static frontend.

## Prerequisites

1.  **Images**: You need to build the Backend and Gateway images and push them to your registry.
    - `backend/Dockerfile` -> `your-registry/clawrag-backend:latest`
    - `frontend/` + `nginx/` -> `your-registry/clawrag-gateway:latest`
2.  **Domain**: Update the Ingress host in `gateway.yaml`.

## Deployment

```bash
kubectl apply -k k8s/clawrag/
```

## Integration with OpenClaw

Once deployed, add the MCP server to OpenClaw:

```bash
openclaw mcp add --transport http clawrag http://clawrag-backend.openclaw.svc.cluster.local:8080/api/v1/rag
```
