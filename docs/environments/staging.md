# Staging Environment

Configuration for the staging environment.

## Specifications

- **Namespace**: `saas-framework-staging`
- **Auto-deploy**: ✅ Yes (on push to release/*)
- **Resources**: Medium (production-like)

## Service Configuration

| Service | Replicas | CPU | Memory | HPA |
|---------|----------|-----|--------|-----|
| API Gateway | 2 | 250m | 256Mi | 2-5 |
| Auth Service | 2 | 250m | 256Mi | - |
| User Service | 2 | 250m | 256Mi | - |
| Tenant Service | 2 | 250m | 256Mi | - |
| Notification Service | 2 | 250m | 256Mi | - |
| System Config Service | 1 | 250m | 256Mi | - |

## Infrastructure

- **MongoDB**: 10Gi storage
- **Redis**: Standard
- **RabbitMQ**: 5Gi storage

## Deployment

```bash
./scripts/deploy.sh staging helm
```
