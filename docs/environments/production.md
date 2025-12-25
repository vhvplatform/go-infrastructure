# Production Environment

Configuration for the production environment.

## Specifications

- **Namespace**: `saas-framework-prod`
- **Auto-deploy**: ❌ No (manual approval required)
- **Resources**: High (optimized for performance)

## Service Configuration

| Service | Replicas | CPU | Memory | HPA Max |
|---------|----------|-----|--------|---------|
| API Gateway | 5 | 500m | 512Mi | 20 |
| Auth Service | 3 | 500m | 512Mi | - |
| User Service | 3 | 500m | 512Mi | - |
| Tenant Service | 3 | 500m | 512Mi | - |
| Notification Service | 3 | 500m | 512Mi | - |
| System Config Service | 2 | 500m | 512Mi | - |

## Infrastructure

- **MongoDB**: Managed, 50Gi storage, 3 replicas
- **Redis**: Managed, 3 replicas
- **RabbitMQ**: 20Gi storage, 3 replicas

## High Availability

- PodDisruptionBudgets enabled
- Multi-zone deployment
- Health checks configured
- Resource limits enforced

## Deployment

```bash
# Manual approval required
./scripts/deploy.sh production helm
```

## Monitoring

- **Logging**: Info/Error only
- **Metrics**: 30s interval
- **Alerts**: PagerDuty + Slack
