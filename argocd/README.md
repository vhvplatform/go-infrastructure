# ArgoCD Applications

GitOps application definitions for the SaaS Platform.

## Structure

```
argocd/
├── app-of-apps.yaml      # Root application
└── applications/
    ├── dev/              # Dev environment
    │   ├── infrastructure.yaml
    │   └── services.yaml
    ├── staging/          # Staging environment
    │   └── infrastructure.yaml
    └── production/       # Production environment
        └── infrastructure.yaml
```

## Usage

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Access ArgoCD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Deploy Applications

```bash
# Deploy app-of-apps (deploys all environments)
kubectl apply -f argocd/app-of-apps.yaml

# Deploy specific environment
kubectl apply -f argocd/applications/dev/
```

## Sync Policies

### Development
- **Auto-sync**: ✅ Enabled
- **Self-heal**: ✅ Enabled
- **Prune**: ✅ Enabled

### Staging
- **Auto-sync**: ✅ Enabled
- **Self-heal**: ✅ Enabled
- **Prune**: ✅ Enabled

### Production
- **Auto-sync**: ❌ Disabled (manual only)
- **Self-heal**: ❌ Disabled
- **Prune**: ❌ Disabled

## ArgoCD CLI

```bash
# Login
argocd login localhost:8080 --username admin

# List applications
argocd app list

# Sync application
argocd app sync go-infrastructure-dev

# View application
argocd app get go-infrastructure-dev

# View diff
argocd app diff go-infrastructure-dev

# Rollback
argocd app rollback go-infrastructure-dev <revision>

# Delete application
argocd app delete go-infrastructure-dev
```

## App-of-Apps Pattern

The `app-of-apps.yaml` creates a parent application that manages all environment applications. This provides:

1. Single point of deployment
2. Consistent configuration
3. Easy environment management
4. Hierarchical structure

## Troubleshooting

### Application OutOfSync

```bash
# Hard refresh
argocd app get <app-name> --hard-refresh

# Manual sync
argocd app sync <app-name>
```

### Sync Failed

```bash
# View sync status
argocd app get <app-name>

# View logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## Best Practices

1. Use app-of-apps for management
2. Enable auto-sync for lower environments
3. Manual sync for production
4. Monitor sync status
5. Use health checks
6. Document sync policies
7. Test in dev first
