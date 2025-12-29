# Go Infrastructure

Complete Infrastructure as Code (IaC) solution for deploying and managing a modern **Hybrid Multi-tenant SaaS platform** on Google Cloud Platform and Kubernetes.

## 📖 Overview

This repository contains all infrastructure configurations for the SaaS Platform, including:

- **Kubernetes Deployments**: Container orchestration with GKE
- **Hybrid Multi-tenant Architecture**: Support for subfolder and custom domain routing
- **Tenant Mapper Service**: Custom domain to tenant ID resolution
- **Redis StatefulSet**: Centralized session and domain mapping storage
- **Terraform Modules**: Cloud infrastructure provisioning (GKE, MongoDB Atlas)
- **Helm Charts**: Package management and deployment templates
- **GitOps Configuration**: ArgoCD for continuous deployment
- **Monitoring Stack**: Prometheus, Grafana, and Loki for observability
- **Automation Scripts**: Deployment and management utilities

## ✨ Key Features

- 🏢 **Hybrid Multi-tenancy**: Support for both subfolder (`saas.com/{tenant}/api/*`) and custom domain (`customer.com/api/*`) routing patterns
- 🔄 **Dynamic Tenant Resolution**: Automatic tenant identification from URL or domain
- 🚀 **Multi-environment support** (dev/staging/production)
- 🔄 **GitOps workflow** with ArgoCD
- 📊 **Complete observability** stack
- 🔒 **Security best practices** built-in
- 🎯 **Infrastructure as Code** for reproducibility
- ⚡ **Auto-scaling** and high availability
- 📦 **Modular architecture** for reusability

## 🏗️ Multi-tenant Architecture

### Traffic Routing Patterns

**Pattern A (Subfolder):**
```
Request: https://saas.com/tenant-123/api/users
    ↓
Nginx Ingress extracts tenant_id = "tenant-123"
    ↓
Injects X-Tenant-ID header
    ↓
Rewrites to: /api/users
    ↓
Routes to backend with X-Tenant-ID: tenant-123
```

**Pattern B (Custom Domain):**
```
Request: https://customer.com/api/users
    ↓
Nginx calls tenant-mapper service
    ↓
Tenant-mapper queries Redis: domain:customer.com → tenant-456
    ↓
Returns X-Tenant-ID: tenant-456
    ↓
Nginx injects header and routes to backend
```

See [detailed deployment guide](docs/HYBRID_MULTITENANT_DEPLOYMENT.md) for more information.

## 📁 Repository Structure

```
infrastructure/
├── services/            # Go microservices
│   ├── tenant-mapper/   # Domain to tenant ID resolution service
│   └── middleware/      # Go tenancy middleware (Gin/Echo)
├── kubernetes/          # Kubernetes manifests with Kustomize
│   ├── base/           # Base manifests
│   │   ├── namespaces/      # Namespace strategy (core, shared, workloads, sandbox)
│   │   ├── network-policies/ # Zero-trust network policies
│   │   ├── ingress/         # Pattern A & B ingress configs
│   │   ├── infrastructure/  # Redis StatefulSet, etc.
│   │   └── services/        # Service deployments
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
│   ├── deploy-multitenant.sh  # Deploy multi-tenant infrastructure
│   ├── test-pattern-a.sh      # Test subfolder routing
│   └── test-pattern-b.sh      # Test custom domain routing
└── docs/              # Documentation
    ├── HYBRID_MULTITENANT_DEPLOYMENT.md     # English guide
    ├── HYBRID_MULTITENANT_DEPLOYMENT_VI.md  # Vietnamese guide
    ├── MULTITENANT_EXAMPLES.md              # Examples & use cases
    ├── TRAFFIC_FLOW_ARCHITECTURE.md         # Complete traffic flow
    └── diagrams/      # PlantUML architecture diagrams
```

## 🚀 Quick Start

**New to this repository?** Check out our guides for step-by-step instructions:
- [**Quick Start Guide**](docs/QUICK_START.md) - Linux/macOS setup (under 30 minutes)
- [**Windows Setup Guide**](docs/windows-setup.md) - Complete Windows developer guide

### Multi-tenant Deployment

```bash
# Deploy to development
./scripts/deploy-multitenant.sh dev kustomize

# Deploy to production with Helm
./scripts/deploy-multitenant.sh prod helm

# Test routing patterns
./scripts/test-pattern-a.sh  # Subfolder routing
./scripts/test-pattern-b.sh  # Custom domain routing
```

### Prerequisites

Ensure you have the following tools installed:

| Tool | Minimum Version | Purpose | Installation |
|------|----------------|---------|--------------|
| `kubectl` | v1.27+ | Kubernetes CLI | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| `kustomize` | v5.0+ | Kubernetes customization | [Install kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/) |
| `helm` | v3.12+ | Kubernetes package manager | [Install helm](https://helm.sh/docs/intro/install/) |
| `terraform` | v1.10+ | Infrastructure provisioning | [Install terraform](https://www.terraform.io/downloads) |
| `gcloud` | Latest | Google Cloud CLI | [Install gcloud](https://cloud.google.com/sdk/docs/install) |
| `go` | v1.21+ | Build tenant-mapper service | [Install Go](https://go.dev/doc/install) |
| `docker` | Latest | Container runtime | [Install Docker](https://docs.docker.com/get-docker/) |
| `docker-compose` | v2.0+ | Multi-container orchestration | [Install Docker Compose](https://docs.docker.com/compose/install/) |

**Additional Requirements:**
- Access to a Kubernetes cluster (GKE or EKS recommended)
- GCP or AWS account with billing enabled
- MongoDB Atlas account (for database)
- Appropriate IAM permissions

### 🚀 Automated Setup

For a quick and automated installation of all prerequisites, use our setup script:

**Linux/macOS:**
```bash
# Clone the repository
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure

# Run the automated setup script
./setup.sh
```

**Windows:**
```powershell
# Clone the repository
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure

# Run the automated setup script (as Administrator)
.\scripts\setup-windows.ps1
```

The setup script will:
- ✅ Detect your operating system (Linux, macOS, or Windows)
- ✅ Install missing dependencies (kubectl, helm, terraform, etc.)
- ✅ Configure environment variables
- ✅ Build the tenant-mapper service
- ✅ Create `.env` configuration file

**Supported Operating Systems:**
- Ubuntu/Debian Linux
- macOS (with Homebrew recommended)
- Windows 10/11 (with PowerShell 5.1+)

### Infrastructure Components

Our infrastructure stack includes:

- **Container Orchestration**: Google Kubernetes Engine (GKE) / Amazon EKS
- **Database**: MongoDB Atlas (managed)
- **Container Registry**: Google Container Registry (GCR) / Amazon ECR
- **Monitoring**: Prometheus + Grafana
- **Logging**: Loki
- **GitOps**: ArgoCD
- **Service Mesh**: (Future: Istio)

## 🐳 Docker Development

### Local Development with Docker Compose

Run the complete infrastructure stack locally using Docker Compose:

```bash
# Start all services (Redis, tenant-mapper, Prometheus, Grafana)
docker-compose up -d

# Start specific services only
docker-compose up -d redis tenant-mapper

# View logs
docker-compose logs -f tenant-mapper

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

**Available Services:**
- **Redis** (port 6379): Tenant mapping and session storage
- **Tenant Mapper** (port 8080): Domain resolution service
- **Prometheus** (port 9090): Metrics collection
- **Grafana** (port 3000): Dashboards and visualization
- **Redis Commander** (port 8081): Redis management UI (optional)

To start optional tools:
```bash
docker-compose --profile tools up -d
```

### Building Docker Images

**Development Image** (with debugging tools):
```bash
docker build -f Dockerfile.dev -t tenant-mapper:dev .
docker run -p 8080:80 tenant-mapper:dev
```

**Production Image** (optimized, minimal size):
```bash
docker build -t tenant-mapper:prod .
docker run -p 8080:80 tenant-mapper:prod
```

### Docker Image Features

**Development (`Dockerfile.dev`):**
- Hot-reload support with Air
- Debug symbols included
- Development tools (bash, curl, git)
- Fast rebuild times

**Production (`Dockerfile`):**
- Multi-stage build for minimal size
- Distroless base image for security
- Non-root user
- Health checks built-in
- Optimized binary (~10MB)

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

## 🏗️ Infrastructure Provisioning with Terraform

### Supported Cloud Providers

This repository includes Terraform modules for both **Google Cloud Platform (GCP)** and **Amazon Web Services (AWS)**.

#### GCP (Google Kubernetes Engine)

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply infrastructure
terraform apply

# Configure kubectl
gcloud container clusters get-credentials saas-framework-dev --region us-central1
```

**GCP Module Features:**
- VPC-native GKE cluster
- Workload Identity for secure authentication
- Auto-scaling node pools
- Private cluster endpoints
- Network policies

#### AWS (Elastic Kubernetes Service)

```bash
cd terraform/environments/dev

# Configure AWS credentials
export AWS_PROFILE=your-profile

# Initialize Terraform
terraform init

# Create VPC and subnets first (if needed)
# Then create EKS cluster
terraform plan -var="provider=aws"
terraform apply -var="provider=aws"

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name saas-framework-dev
```

**AWS Module Features:**
- EKS managed cluster
- IAM Roles for Service Accounts (IRSA)
- Auto-scaling node groups
- VPC and subnet configuration
- CloudWatch logging integration

### Terraform Module Usage Example

**Using GCP Module:**
```hcl
module "gke_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id   = var.project_id
  cluster_name = "saas-framework-prod"
  region       = "us-central1"
  
  min_node_count = 3
  max_node_count = 10
  machine_type   = "e2-standard-4"
}
```

**Using AWS Module:**
```hcl
module "eks_cluster" {
  source = "../../modules/kubernetes-cluster-aws"
  
  cluster_name    = "saas-framework-prod"
  subnet_ids      = var.subnet_ids
  
  min_node_count     = 3
  max_node_count     = 10
  instance_types     = ["t3.large"]
}
```

### Terraform State Management

Configure remote state backend for team collaboration:

**GCP (Cloud Storage):**
```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "prod/terraform.tfstate"
  }
}
```

**AWS (S3):**
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
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

## 🔄 CI/CD Pipeline

### Automated Testing

The repository includes comprehensive CI/CD pipelines:

**Test Pipeline** (`.github/workflows/ci-test.yml`):
- ✅ **Unit Tests**: Go service tests with race detection
- ✅ **Integration Tests**: Docker Compose-based service integration
- ✅ **E2E Tests**: Full stack end-to-end testing
- ✅ **Security Scans**: Trivy vulnerability scanning
- ✅ **Code Quality**: Coverage reporting with Codecov
- ✅ **Infrastructure Validation**: Terraform, Helm, and Kubernetes manifest validation

**Deployment Pipelines**:
- **Development**: Auto-deploys on push to `main` branch
- **Staging**: Auto-deploys on push to `release/*` branches
- **Production**: Manual deployment via workflow dispatch

### Running Tests Locally

```bash
# Run Go unit tests
cd services/tenant-mapper
go test -v -race ./...

# Run integration tests with Docker Compose
docker-compose up -d
# Run your test suite
docker-compose down -v

# Validate Kubernetes manifests
kustomize build kubernetes/overlays/dev | kubectl apply --dry-run=client -f -

# Validate Terraform
cd terraform/environments/dev
terraform init -backend=false
terraform validate
```

### CI/CD Best Practices

1. **Branch Protection**: Enable required status checks on `main` branch
2. **Secrets Management**: Store sensitive data in GitHub Secrets
3. **Environment-specific Configs**: Use separate values files for each environment
4. **Automated Rollbacks**: Production pipeline includes automatic rollback on failure
5. **Security Scanning**: All images scanned for vulnerabilities before deployment

## 🐛 Troubleshooting

### Common Issues and Solutions

#### Setup Script Issues

**Issue**: Permission denied when running setup.sh
```bash
chmod +x setup.sh
./setup.sh
```

**Issue**: Homebrew not installed on macOS
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Docker Issues

**Issue**: Docker daemon not running
```bash
# Linux
sudo systemctl start docker

# macOS
# Start Docker Desktop from Applications
```

**Issue**: Permission denied when running Docker commands
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**Issue**: Port already in use
```bash
# Check what's using the port
lsof -i :8080
# Or change the port in docker-compose.yml
```

#### Kubernetes Deployment Issues

**Issue**: Pod stuck in Pending state
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc -n <namespace>
```

**Issue**: ImagePullBackOff error
```bash
# Verify image exists
docker pull <image-name>

# Check image pull secrets
kubectl get secrets -n <namespace>

# Verify service account has proper permissions
kubectl describe sa -n <namespace>
```

**Issue**: CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace> --previous

# Check resource limits
kubectl describe pod <pod-name> -n <namespace>

# Verify environment variables
kubectl exec <pod-name> -n <namespace> -- env
```

#### Terraform Issues

**Issue**: Backend initialization failure
```bash
# For GCS backend, ensure bucket exists
gsutil mb gs://your-terraform-state-bucket

# For S3 backend, create bucket first
aws s3 mb s3://your-terraform-state-bucket
```

**Issue**: Provider authentication errors
```bash
# GCP
gcloud auth application-default login
export GOOGLE_PROJECT=your-project-id

# AWS
aws configure
export AWS_PROFILE=your-profile
```

**Issue**: Resource already exists
```bash
# Import existing resource
terraform import <resource_type>.<resource_name> <resource_id>

# Or remove from state and recreate
terraform state rm <resource_type>.<resource_name>
```

#### Service-Specific Issues

**Tenant Mapper Service**:
```bash
# Check Redis connectivity
kubectl exec -it <tenant-mapper-pod> -n <namespace> -- wget -O- http://redis:6379

# Verify environment variables
kubectl exec <tenant-mapper-pod> -n <namespace> -- env | grep REDIS

# Check service logs
kubectl logs -f <tenant-mapper-pod> -n <namespace>
```

**Redis Issues**:
```bash
# Connect to Redis CLI
kubectl exec -it redis-0 -n <namespace> -- redis-cli

# Test Redis connectivity
redis-cli ping

# Check Redis persistence
redis-cli CONFIG GET dir
```

### Performance Troubleshooting

**High CPU/Memory Usage**:
```bash
# Check resource usage
kubectl top pods -n <namespace>
kubectl top nodes

# Review resource limits and requests
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Limits\|Requests"
```

**Slow Response Times**:
```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Verify DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>

# Check network policies
kubectl get networkpolicies -n <namespace>
```

### Getting Help

If you encounter issues not covered here:

1. **Check logs**: Use `kubectl logs` and `docker-compose logs`
2. **Review events**: Use `kubectl get events -n <namespace>`
3. **Consult documentation**: See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
4. **Open an issue**: Create a GitHub issue with detailed information
5. **Contact support**: Reach out on Slack #go-infrastructure

## 📚 Documentation

### Multi-tenant Architecture Guides

- **[Hybrid Multi-tenant Deployment Guide (English)](docs/HYBRID_MULTITENANT_DEPLOYMENT.md)** - Complete guide for deploying hybrid multi-tenant infrastructure
- **[Hướng dẫn Triển khai Đa-thuê bao Lai (Tiếng Việt)](docs/HYBRID_MULTITENANT_DEPLOYMENT_VI.md)** - Hướng dẫn đầy đủ bằng tiếng Việt
- [Tenant Mapper Service](services/tenant-mapper/README.md) - Domain resolution service documentation

### Architecture Diagrams

- [Overall Architecture](docs/diagrams/architecture-overview.puml) - Complete system architecture
- [Traffic Flow - Pattern A](docs/diagrams/traffic-flow-pattern-a.puml) - Subfolder routing flow
- [Traffic Flow - Pattern B](docs/diagrams/traffic-flow-pattern-b.puml) - Custom domain routing flow
- [Deployment Flow](docs/diagrams/deployment-flow.puml) - CI/CD deployment process

### General Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [Architecture](docs/ARCHITECTURE.md) - Infrastructure architecture
- [GitOps Workflow](docs/GITOPS.md) - GitOps best practices
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- **[Windows Setup Guide](docs/windows-setup.md)** - Complete guide for Windows developers
- [Extraction Guide](EXTRACTION_GUIDE.md) - How to extract to separate repo
- **[Traffic Flow Architecture](docs/TRAFFIC_FLOW_ARCHITECTURE.md)** - Complete scalable architecture guide

### Kubernetes Resources

- [Namespace Strategy](kubernetes/base/namespaces/namespaces.yaml) - 4-tier namespace architecture
- [Network Policies](kubernetes/base/network-policies/network-policy-sandbox.yaml) - Zero-trust security
- [Go Middleware](services/middleware/README.md) - Tenancy middleware for Gin/Echo

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

- [go-framework](https://github.com/vhvplatform/go-framework) - Main monorepo
- [go-shared](https://github.com/vhvplatform/go-shared) - Shared libraries
- Individual service repositories (after extraction)
