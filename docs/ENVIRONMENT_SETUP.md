# Environment Setup Guide

This guide provides instructions for setting up Development, Staging, and Production environments.

## 📋 Overview

The infrastructure supports three environments:
- **Development**: For active development and testing
- **Staging**: Pre-production environment for final testing
- **Production**: Live environment serving end users

## 🏗️ Environment Configurations

### Development Environment

**Purpose**: Active development and feature testing

**Configuration**:
- GKE Cluster: 3-5 nodes (e2-standard-4)
- MongoDB: M10 instance
- Auto-scaling: Enabled
- Preemptible VMs: Yes (cost savings)
- Point-in-time recovery: Disabled
- Backup retention: 7 days

**Access**:
- Auto-deployment from `main` branch
- All developers have access
- IP restrictions: Relaxed

### Staging Environment

**Purpose**: Pre-production testing and QA

**Configuration**:
- GKE Cluster: 3-8 nodes (n2-standard-4)
- MongoDB: M20 instance
- Auto-scaling: Enabled
- Preemptible VMs: No
- Point-in-time recovery: Enabled
- Backup retention: 14 days

**Access**:
- Auto-deployment from `release/*` branches
- QA team and senior developers
- IP restrictions: Moderate

### Production Environment

**Purpose**: Live environment serving customers

**Configuration**:
- GKE Cluster: 5-20 nodes (n2-standard-8)
- MongoDB: M30+ instance
- Auto-scaling: Enabled
- Preemptible VMs: No
- Point-in-time recovery: Enabled
- Backup retention: 30 days

**Access**:
- Manual deployment only
- Platform team and release managers
- IP restrictions: Strict

## 🚀 Setup Instructions

### Prerequisites

1. GCP Project created for each environment
2. MongoDB Atlas projects for each environment
3. Service accounts with appropriate IAM roles
4. API keys for MongoDB Atlas
5. Terraform installed (v1.10+)

### Step 1: Prepare GCP Project

```bash
# Set project ID
export PROJECT_ID="your-project-id"
export ENVIRONMENT="dev|staging|prod"

# Create project (if needed)
gcloud projects create $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=$PROJECT_ID

# Create service account for Terraform
gcloud iam service-accounts create terraform-sa \
  --display-name "Terraform Service Account" \
  --project=$PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 2: Create GCS Bucket for Terraform State

```bash
# Create bucket for Terraform state
gsutil mb -p $PROJECT_ID gs://${PROJECT_ID}-terraform-state

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Set lifecycle policy (optional)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"numNewerVersions": 10}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://${PROJECT_ID}-terraform-state
```

### Step 3: Configure MongoDB Atlas

```bash
# Create MongoDB Atlas project via UI or API
# 1. Go to https://cloud.mongodb.com
# 2. Create new project for the environment
# 3. Generate API keys with Project Owner permissions
# 4. Save public and private keys securely
```

### Step 4: Configure Terraform

```bash
# Navigate to environment directory
cd terraform/environments/$ENVIRONMENT

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vi terraform.tfvars

# Update backend configuration in main.tf
# Change bucket name to match your GCS bucket
```

### Step 5: Initialize and Deploy

```bash
# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/terraform-key.json"
export TF_VAR_mongodb_atlas_public_key="your-public-key"
export TF_VAR_mongodb_atlas_private_key="your-private-key"
export TF_VAR_mongodb_password="your-secure-password"

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply configuration
terraform apply

# Save outputs
terraform output -json > outputs.json
```

### Step 6: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) \
  --region $(terraform output -raw gke_cluster_location) \
  --project $PROJECT_ID

# Verify connection
kubectl get nodes
```

### Step 7: Deploy ArgoCD (Optional)

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 8: Deploy Applications

```bash
# Using kubectl + kustomize
kubectl apply -k kubernetes/overlays/$ENVIRONMENT

# Using Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.$ENVIRONMENT.yaml \
  --namespace saas-framework-$ENVIRONMENT \
  --create-namespace

# Using ArgoCD
kubectl apply -f argocd/applications/$ENVIRONMENT/
```

## 🔒 Security Checklist

### Pre-Deployment Security

- [ ] Service account has minimum required permissions
- [ ] API keys are stored in secure secret management
- [ ] Network policies are configured
- [ ] Firewall rules are restrictive
- [ ] MongoDB IP whitelist is properly configured
- [ ] SSL/TLS certificates are valid
- [ ] Secrets are encrypted at rest
- [ ] RBAC policies are configured

### Post-Deployment Security

- [ ] Verify Workload Identity is working
- [ ] Test network policies
- [ ] Verify encryption in transit
- [ ] Enable audit logging
- [ ] Configure security scanning
- [ ] Set up vulnerability alerts
- [ ] Enable GKE Binary Authorization
- [ ] Configure Pod Security Policies

## 📊 Environment Comparison

| Feature | Development | Staging | Production |
|---------|------------|---------|------------|
| **GKE Nodes** | 3-5 | 3-8 | 5-20 |
| **Node Type** | e2-standard-4 | n2-standard-4 | n2-standard-8 |
| **Preemptible** | Yes | No | No |
| **MongoDB** | M10 | M20 | M30+ |
| **PIT Recovery** | No | Yes | Yes |
| **Backup Retention** | 7 days | 14 days | 30 days |
| **Auto-deploy** | Yes | Yes | No |
| **Cost (Monthly)** | ~$250 | ~$600 | ~$1500+ |

## 🔄 Environment Management

### Updating Infrastructure

```bash
cd terraform/environments/$ENVIRONMENT

# Review changes
terraform plan

# Apply updates
terraform apply

# If issues occur, rollback
terraform apply -target=resource.name
```

### Scaling

```bash
# Scale GKE nodes
gcloud container clusters resize CLUSTER_NAME \
  --node-pool POOL_NAME \
  --num-nodes 10

# Or use Terraform
# Update max_node_count in terraform.tfvars
terraform apply
```

### Disaster Recovery

```bash
# Backup current state
terraform state pull > backup-state.json

# Restore from backup
terraform state push backup-state.json

# MongoDB restore
# Use MongoDB Atlas UI or CLI to restore from snapshot
```

## 🆘 Troubleshooting

### Issue: Terraform state locked

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Issue: GKE cluster unreachable

```bash
# Refresh credentials
gcloud container clusters get-credentials CLUSTER_NAME \
  --region REGION --project PROJECT_ID

# Verify cluster is running
gcloud container clusters describe CLUSTER_NAME \
  --region REGION --project PROJECT_ID
```

### Issue: MongoDB connection failures

```bash
# Verify IP whitelist
# Check MongoDB Atlas console

# Test connection
mongosh "mongodb+srv://cluster.mongodb.net" \
  --username USERNAME --password PASSWORD
```

## 📚 Additional Resources

- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [MongoDB Atlas Production Notes](https://www.mongodb.com/docs/atlas/reference/production-notes/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Support

For issues or questions:
1. Check the [Troubleshooting Guide](../TROUBLESHOOTING.md)
2. Review closed GitHub issues
3. Create a new issue with details
4. Contact the platform team

## 📝 Maintenance Schedule

- **Development**: Rolling updates, no maintenance window
- **Staging**: Updates Tuesday/Thursday 22:00-23:00 UTC
- **Production**: Updates Sunday 02:00-04:00 UTC (approved changes only)
