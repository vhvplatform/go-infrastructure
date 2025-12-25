# Helm Charts

Helm charts for deploying the SaaS Platform.

## Structure

```
helm/
└── charts/
    ├── saas-platform/      # Umbrella chart (all services)
    ├── infrastructure/     # MongoDB, Redis, RabbitMQ
    └── microservices/      # Reusable service template
```

## Charts

### saas-platform (Umbrella Chart)

Main chart that includes all components:
- Infrastructure components (via dependencies)
- All microservices (via dependencies)
- Shared configurations

**Usage:**
```bash
helm install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework-dev \
  --create-namespace
```

### infrastructure

Infrastructure components:
- MongoDB (database)
- Redis (cache)
- RabbitMQ (message queue)

### microservices

Reusable template for microservices with:
- Deployment
- Service
- HorizontalPodAutoscaler
- ServiceMonitor (Prometheus)
- PodDisruptionBudget

## Values Files

- `values.yaml` - Default production values
- `values.dev.yaml` - Development overrides
- `values.staging.yaml` - Staging overrides
- `values.prod.yaml` - Production overrides

## Usage

### Install

```bash
helm install <release-name> <chart-path> -f <values-file>
```

### Upgrade

```bash
helm upgrade <release-name> <chart-path> -f <values-file>
```

### Uninstall

```bash
helm uninstall <release-name>
```

### Template (dry-run)

```bash
helm template <release-name> <chart-path> -f <values-file>
```

### Lint

```bash
helm lint <chart-path>
```

## Development

### Creating a New Chart

```bash
helm create mychart
```

### Testing Charts

```bash
# Lint
helm lint helm/charts/saas-platform

# Template
helm template test helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml

# Dry-run install
helm install test helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --dry-run
```

## Best Practices

1. Use umbrella charts for related services
2. Extract common templates to _helpers.tpl
3. Parameterize everything with values
4. Provide sensible defaults
5. Document all values
6. Version charts properly
7. Test with all value files
