# Quick Start Guide

This guide will help you get the Go Infrastructure platform up and running in under 30 minutes.

## Choose Your Path

### Path 1: Local Development (Recommended for testing)
**Time**: ~10 minutes  
**Requirements**: Docker and Docker Compose

### Path 2: Cloud Deployment - GCP
**Time**: ~30 minutes  
**Requirements**: GCP account, gcloud CLI

### Path 3: Cloud Deployment - AWS
**Time**: ~30 minutes  
**Requirements**: AWS account, AWS CLI

---

## Path 1: Local Development with Docker

### Step 1: Clone the Repository

```bash
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure
```

### Step 2: Run Setup Script

```bash
# Make script executable and run
chmod +x setup.sh
./setup.sh
```

The setup script will install:
- Docker and Docker Compose
- kubectl, helm, kustomize
- Go programming language
- All other required tools

### Step 3: Start Services

```bash
# Start all services
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 4: Verify Installation

```bash
# Check tenant-mapper service
curl http://localhost:8080/health

# Check Redis
docker-compose exec redis redis-cli ping

# Access Grafana
open http://localhost:3000  # Default credentials: admin/admin

# Access Prometheus
open http://localhost:9090
```

### Step 5: Test the Platform

```bash
# Store a test tenant mapping in Redis
docker-compose exec redis redis-cli SET "domain:example.com" "tenant-123"

# Verify the mapping
docker-compose exec redis redis-cli GET "domain:example.com"

# Check tenant-mapper logs
docker-compose logs tenant-mapper
```

**🎉 Success!** Your local development environment is ready.

---

## Path 2: Cloud Deployment on GCP

### Prerequisites

- GCP account with billing enabled
- Project created in GCP Console
- gcloud CLI installed and configured

### Step 1: Setup Environment

```bash
# Clone repository
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure

# Run automated setup
./setup.sh

# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set project
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID
```

### Step 2: Provision Infrastructure with Terraform

```bash
cd terraform/environments/dev

# Configure variables
cat > terraform.tfvars << EOF
project_id = "$GCP_PROJECT_ID"
region     = "us-central1"
cluster_name = "saas-framework-dev"

# MongoDB Atlas credentials
mongodb_atlas_public_key  = "your-public-key"
mongodb_atlas_private_key = "your-private-key"
mongodb_atlas_org_id      = "your-org-id"
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply
```

**Note**: This will take ~15-20 minutes to provision the GKE cluster.

### Step 3: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials saas-framework-dev \
  --region us-central1 \
  --project $GCP_PROJECT_ID

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 4: Deploy Application

```bash
cd ../../../  # Back to repository root

# Deploy using Kustomize
kubectl apply -k kubernetes/overlays/dev

# Wait for pods to be ready
kubectl get pods -n saas-framework-dev --watch

# Check deployment status
kubectl get all -n saas-framework-dev
```

### Step 5: Access Services

```bash
# Get ingress IP
kubectl get ingress -n saas-framework-dev

# Port-forward for local access
kubectl port-forward -n saas-framework-dev svc/tenant-mapper 8080:80

# Test the service
curl http://localhost:8080/health
```

**🎉 Success!** Your GCP deployment is complete.

---

## Path 3: Cloud Deployment on AWS

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI installed and configured
- kubectl installed

### Step 1: Setup Environment

```bash
# Clone repository
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure

# Run automated setup
./setup.sh

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID, Secret Key, and default region
```

### Step 2: Provision Infrastructure with Terraform

```bash
cd terraform/examples/aws

# Configure variables
cat > terraform.tfvars << EOF
region             = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

kubernetes_version = "1.28"

desired_node_count = 3
min_node_count     = 1
max_node_count     = 10
instance_types     = ["t3.medium"]

allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply
```

**Note**: This will take ~15-20 minutes to provision the EKS cluster.

### Step 3: Configure kubectl

```bash
# Configure kubectl (command will be in terraform output)
aws eks update-kubeconfig --region us-east-1 --name saas-framework-dev

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 4: Deploy Application

```bash
cd ../../../  # Back to repository root

# Deploy using Kustomize
kubectl apply -k kubernetes/overlays/dev

# Wait for pods to be ready
kubectl get pods -n saas-framework-dev --watch

# Check deployment status
kubectl get all -n saas-framework-dev
```

### Step 5: Install AWS Load Balancer Controller (Optional)

```bash
# Required for AWS ingress
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=saas-framework-dev
```

### Step 6: Access Services

```bash
# Port-forward for local access
kubectl port-forward -n saas-framework-dev svc/tenant-mapper 8080:80

# Test the service
curl http://localhost:8080/health
```

**🎉 Success!** Your AWS deployment is complete.

---

## Next Steps

### 1. Configure Monitoring

```bash
# Deploy Prometheus and Grafana
kubectl apply -k monitoring/

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

### 2. Set Up GitOps with ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy applications
kubectl apply -f argocd/app-of-apps.yaml

# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### 3. Configure Domain Routing

For custom domain routing (Pattern B), configure your domain mappings:

```bash
# Connect to Redis
kubectl exec -it redis-0 -n saas-framework-dev -- redis-cli

# Add domain mappings
SET domain:customer1.com tenant-123
SET domain:customer2.com tenant-456
```

### 4. Run Tests

```bash
# Test subfolder routing (Pattern A)
./scripts/test-pattern-a.sh

# Test custom domain routing (Pattern B)
./scripts/test-pattern-b.sh
```

## Troubleshooting

### Docker Issues

```bash
# Check Docker status
docker ps
docker-compose ps

# View logs
docker-compose logs -f service-name

# Restart services
docker-compose restart
```

### Kubernetes Issues

```bash
# Check pod status
kubectl get pods -n saas-framework-dev

# View pod logs
kubectl logs -f <pod-name> -n saas-framework-dev

# Describe pod for events
kubectl describe pod <pod-name> -n saas-framework-dev

# Check service endpoints
kubectl get endpoints -n saas-framework-dev
```

### Terraform Issues

```bash
# View terraform output
terraform output

# Refresh state
terraform refresh

# Show current state
terraform show
```

## Clean Up

### Local Development

```bash
# Stop all services
docker-compose down -v
```

### Cloud Deployment (GCP)

```bash
cd terraform/environments/dev
terraform destroy
```

### Cloud Deployment (AWS)

```bash
cd terraform/examples/aws

# Delete Kubernetes resources first
kubectl delete -k ../../../kubernetes/overlays/dev

# Then destroy infrastructure
terraform destroy
```

## Additional Resources

- [Complete Documentation](../README.md)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Multi-tenant Deployment](docs/HYBRID_MULTITENANT_DEPLOYMENT.md)

## Getting Help

- 📧 Email: team@saas-framework.io
- 💬 Slack: #go-infrastructure
- 🐛 Issues: [GitHub Issues](https://github.com/vhvplatform/go-infrastructure/issues)
