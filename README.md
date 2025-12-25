# Go Infrastructure

Complete Infrastructure as Code (IaC) solution for deploying and managing a modern SaaS platform on Google Cloud Platform and Kubernetes.

## 📖 Overview

This repository contains all infrastructure configurations for the SaaS Platform, including:

- **Kubernetes Deployments**: Container orchestration with GKE
- **Terraform Modules**: Cloud infrastructure provisioning (GKE, MongoDB Atlas)
- **Helm Charts**: Package management and deployment templates
- **GitOps Configuration**: ArgoCD for continuous deployment
- **Monitoring Stack**: Prometheus, Grafana, and Loki for observability
- **Automation Scripts**: Deployment and management utilities

## ✨ Key Features

- 🚀 **Multi-environment support** (dev/staging/production)
- 🔄 **GitOps workflow** with ArgoCD
- 📊 **Complete observability** stack
- 🔒 **Security best practices** built-in
- 🎯 **Infrastructure as Code** for reproducibility
- ⚡ **Auto-scaling** and high availability
- 📦 **Modular architecture** for reusability

## 📁 Repository Structure

```
infrastructure/
├── kubernetes/          # Kubernetes manifests with Kustomize
│   ├── base/           # Base manifests
│   └── overlays/       # Environment-specific overlays (dev/staging/prod)
├── helm/               # Helm charts for deployment
│   └── charts/
│       ├── saas-platform/      # Umbrella chart
│       ├── infrastructure/      # Infrastructure components
│       └── microservices/       # Reusable service template
├── terraform/          # Infrastructure provisioning
│   ├── modules/        # Reusable Terraform modules
│   └── environments/   # Environment-specific configs
├── argocd/            # GitOps configurations
│   ├── applications/  # ArgoCD application manifests
│   └── app-of-apps.yaml
├── monitoring/        # Observability configs
│   ├── prometheus/    # Metrics collection
│   ├── grafana/       # Dashboards
│   ├── loki/          # Log aggregation
│   └── alerts/        # Alert configurations
├── scripts/           # Deployment automation scripts
└── docs/              # Documentation
```

## 🚀 Quick Start

### Prerequisites

Ensure you have the following tools installed:

| Tool | Minimum Version | Purpose | Installation |
|------|----------------|---------|--------------|
| `kubectl` | v1.27+ | Kubernetes CLI | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| `kustomize` | v5.0+ | Kubernetes customization | [Install kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) |
| `helm` | v3.12+ | Kubernetes package manager | [Install helm](https://helm.sh/docs/intro/install/) |
| `terraform` | v1.10+ | Infrastructure provisioning | [Install terraform](https://www.terraform.io/downloads) |
| `gcloud` | Latest | Google Cloud CLI | [Install gcloud](https://cloud.google.com/sdk/docs/install) |

**Additional Requirements:**
- Access to a Kubernetes cluster (GKE recommended)
- GCP account with billing enabled
- MongoDB Atlas account (for database)
- Appropriate IAM permissions

### Infrastructure Components

Our infrastructure stack includes:

- **Container Orchestration**: Google Kubernetes Engine (GKE)
- **Database**: MongoDB Atlas (managed)
- **Container Registry**: Google Container Registry (GCR)
- **Monitoring**: Prometheus + Grafana
- **Logging**: Loki
- **GitOps**: ArgoCD
- **Service Mesh**: (Future: Istio)

### Deploy to Development

```bash
cd infrastructure
./scripts/deploy.sh dev
```

### Deploy to Production

```bash
cd infrastructure
./scripts/deploy.sh production helm
```

## 📦 Deployment Methods

### 1. Kubectl + Kustomize

```bash
# Dry-run
kubectl apply -k kubernetes/overlays/dev --dry-run=server

# Apply
kubectl apply -k kubernetes/overlays/dev
```

### 2. Helm

```bash
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework-dev \
  --create-namespace
```

### 3. ArgoCD (GitOps)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy app-of-apps
kubectl apply -f argocd/app-of-apps.yaml
```

## 🌍 Environments

| Environment | Namespace | Auto-deploy | Replicas | Resources |
|------------|-----------|-------------|----------|-----------|
| **Development** | `saas-framework-dev` | ✅ Yes (main) | 1 | Low |
| **Staging** | `saas-framework-staging` | ✅ Yes (release/*) | 2 | Medium |
| **Production** | `saas-framework-prod` | ❌ Manual | 3-5 | High |

## 📊 Monitoring

Access monitoring dashboards:

```bash
# Port-forward Grafana
kubectl port-forward -n saas-framework svc/grafana 3000:3000

# Port-forward Prometheus
kubectl port-forward -n saas-framework svc/prometheus 9090:9090
```

## 🔐 Secret Management

```bash
# Create secrets
./scripts/secrets-mgmt.sh dev create

# Update a secret
./scripts/secrets-mgmt.sh dev update JWT_SECRET "new-value"

# View secrets
./scripts/secrets-mgmt.sh dev view
```

## 🔄 Rollback

```bash
# Rollback to previous version
./scripts/rollback.sh production 1

# Rollback to specific revision
./scripts/rollback.sh production 3
```

## ✅ Validation

```bash
# Validate all manifests
./scripts/validate-manifests.sh dev

# Validate specific environment
./scripts/validate-manifests.sh production
```

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [Architecture](docs/ARCHITECTURE.md) - Infrastructure architecture
- [GitOps Workflow](docs/GITOPS.md) - GitOps best practices
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Extraction Guide](EXTRACTION_GUIDE.md) - How to extract to separate repo

### Environment-specific Docs

- [Development](docs/environments/dev.md)
- [Staging](docs/environments/staging.md)
- [Production](docs/environments/production.md)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run validation: `./scripts/validate-manifests.sh dev`
4. Submit a pull request

## 📝 License

See [LICENSE](LICENSE) file for details.

## 🆘 Support

- Create an issue in the repository
- Contact: team@saas-framework.io
- Slack: #go-infrastructure

## 🔗 Related Repositories

- [go-framework](https://github.com/vhvcorp/go-framework) - Main monorepo
- [go-shared](https://github.com/vhvcorp/go-shared) - Shared libraries
- Individual service repositories (after extraction)
