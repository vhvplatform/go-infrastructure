# Deployment Guide

Complete guide for deploying the SaaS Platform infrastructure.

## Prerequisites

### Required Tools

- **kubectl** v1.27+ - Kubernetes CLI
- **kustomize** v5.0+ - Kubernetes configuration management
- **helm** v3.12+ - Kubernetes package manager
- **terraform** v1.5+ - Infrastructure provisioning (optional)
- **docker** - For building container images

### Installation

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## Deployment Methods

### Method 1: Kubectl + Kustomize (Recommended)

Best for: Direct deployments, GitOps workflows

```bash
# Navigate to infrastructure directory
cd infrastructure

# Dry-run to verify changes
kubectl apply -k kubernetes/overlays/dev --dry-run=server

# Apply to cluster
kubectl apply -k kubernetes/overlays/dev

# Verify deployment
kubectl get pods -n saas-framework-dev
```

### Method 2: Helm

Best for: Parameterized deployments, versioned releases

```bash
cd infrastructure

# Install/upgrade with Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework-dev \
  --create-namespace \
  --wait \
  --timeout 10m

# Check release status
helm list -n saas-framework-dev

# View release history
helm history saas-platform -n saas-framework-dev
```

### Method 3: ArgoCD (GitOps)

Best for: Automated, auditable deployments

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Deploy applications
kubectl apply -f argocd/app-of-apps.yaml

# Watch sync status
kubectl get applications -n argocd -w
```

## Environment-Specific Deployments

### Development

- **Auto-deploy**: Enabled on push to `main`
- **Replicas**: 1 per service
- **Resources**: Minimal (128Mi RAM, 100m CPU)
- **Monitoring**: Debug logs enabled

```bash
./scripts/deploy.sh dev kustomize
```

### Staging

- **Auto-deploy**: Enabled on push to `release/*`
- **Replicas**: 2 per service
- **Resources**: Medium (256Mi RAM, 250m CPU)
- **Monitoring**: Info logs

```bash
./scripts/deploy.sh staging helm
```

### Production

- **Auto-deploy**: Disabled (manual approval required)
- **Replicas**: 3-5 per service with HPA
- **Resources**: High (512Mi-1Gi RAM, 500m-1 CPU)
- **PodDisruptionBudgets**: Enabled
- **Monitoring**: Error/warn logs only

```bash
./scripts/deploy.sh production helm
```

## Post-Deployment Verification

```bash
# Check all pods are running
kubectl get pods -n saas-framework-dev

# Check services
kubectl get svc -n saas-framework-dev

# Check ingress
kubectl get ingress -n saas-framework-dev

# View logs
kubectl logs -f -n saas-framework-dev -l app=api-gateway

# Check resource usage
kubectl top pods -n saas-framework-dev
```

## Rollback Procedure

```bash
# View rollout history
kubectl rollout history deployment/api-gateway -n saas-framework-dev

# Rollback to previous version
./scripts/rollback.sh dev 1

# Rollback to specific revision
./scripts/rollback.sh dev 3
```

## Troubleshooting

### Pods not starting

```bash
# Describe pod
kubectl describe pod <pod-name> -n saas-framework-dev

# Check events
kubectl get events -n saas-framework-dev --sort-by='.lastTimestamp'

# View logs
kubectl logs <pod-name> -n saas-framework-dev
```

### Image pull errors

```bash
# Check image pull secrets
kubectl get secrets -n saas-framework-dev

# Create/update image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token> \
  -n saas-framework-dev
```

## Best Practices

1. **Always validate** before deploying: `./scripts/validate-manifests.sh <env>`
2. **Use dry-run** first: `--dry-run=server`
3. **Monitor deployments**: Watch pods and logs during rollout
4. **Test in dev** before promoting to staging/prod
5. **Keep secrets secure**: Never commit secrets to git
6. **Document changes**: Update CHANGELOG.md
7. **Tag releases**: Use semantic versioning

## CI/CD Integration

GitHub Actions workflows are configured for automated deployments:

- `.github/workflows/validate.yml` - Validates on PR
- `.github/workflows/deploy-dev.yml` - Auto-deploys to dev
- `.github/workflows/deploy-staging.yml` - Auto-deploys to staging
- `.github/workflows/deploy-prod.yml` - Manual production deployment

## Next Steps

- [Architecture Documentation](ARCHITECTURE.md)
- [GitOps Workflow](GITOPS.md)
- [Monitoring Setup](../monitoring/README.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
