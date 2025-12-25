# Kubernetes Manifests

Kubernetes manifests organized with Kustomize for the SaaS Platform.

## Structure

```
kubernetes/
├── base/                    # Base manifests
│   ├── kustomization.yaml  # Base kustomization
│   ├── namespace.yaml      # Namespace definition
│   ├── configmaps/         # Application configs
│   ├── secrets/            # Secret templates
│   ├── infrastructure/     # MongoDB, Redis, RabbitMQ
│   ├── services/           # Microservice deployments
│   └── ingress/            # Ingress configuration
└── overlays/               # Environment-specific
    ├── dev/                # Development overlay
    ├── staging/            # Staging overlay
    └── production/         # Production overlay
```

## Usage

### Build manifests

```bash
# Development
kustomize build kubernetes/overlays/dev

# Staging
kustomize build kubernetes/overlays/staging

# Production
kustomize build kubernetes/overlays/production
```

### Apply to cluster

```bash
# Development
kubectl apply -k kubernetes/overlays/dev

# Production
kubectl apply -k kubernetes/overlays/production
```

### Dry-run

```bash
kubectl apply -k kubernetes/overlays/dev --dry-run=server
```

## Customization

Each overlay can customize:
- Namespaces
- Replicas
- Resource limits
- Image tags
- Environment variables
- ConfigMaps
- Secrets

## Best Practices

1. Keep base manifests minimal
2. Use overlays for environment differences
3. Never commit secrets
4. Test in dev before higher environments
5. Use consistent labels
6. Document all customizations
