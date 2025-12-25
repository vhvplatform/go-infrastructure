# Development Environment

Configuration and setup for the development environment.

## Specifications

- **Namespace**: `saas-framework-dev`
- **Cluster**: Development GKE cluster
- **Auto-deploy**: ✅ Yes (on push to main)
- **Resources**: Low (cost-optimized)

## Service Configuration

| Service | Replicas | CPU | Memory |
|---------|----------|-----|--------|
| API Gateway | 1 | 100m | 128Mi |
| Auth Service | 1 | 100m | 128Mi |
| User Service | 1 | 100m | 128Mi |
| Tenant Service | 1 | 100m | 128Mi |
| Notification Service | 1 | 100m | 128Mi |
| System Config Service | 1 | 100m | 128Mi |

## Infrastructure

- **MongoDB**: Single instance, 5Gi storage
- **Redis**: Single instance
- **RabbitMQ**: Single instance, 2Gi storage

## Deployment

```bash
# Deploy with Kustomize
kubectl apply -k kubernetes/overlays/dev

# Deploy with Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework-dev \
  --create-namespace

# Deploy with script
./scripts/deploy.sh dev
```

## Access

```bash
# Port-forward API Gateway
kubectl port-forward svc/api-gateway 8080:8080 -n saas-framework-dev

# Port-forward Grafana
kubectl port-forward svc/grafana 3000:3000 -n saas-framework-dev
```

## Monitoring

- **Logging**: Debug level enabled
- **Metrics**: 30s interval
- **Alerts**: Disabled (notifications to Slack)

## Notes

- Preemptible nodes used for cost savings
- Auto-scaling disabled
- No PodDisruptionBudgets
- Suitable for testing and development only
