# Terraform Infrastructure

Infrastructure as Code using Terraform for provisioning cloud resources on Google Cloud Platform and MongoDB Atlas.

## 📋 Overview

This directory contains Terraform configurations for deploying and managing:
- **Google Kubernetes Engine (GKE)** clusters for container orchestration
- **MongoDB Atlas** managed database clusters
- Future: Redis cache, VPC networking, load balancers, and more

## 📁 Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── kubernetes-cluster/   # GKE cluster provisioning
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── managed-database/     # MongoDB Atlas cluster
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── managed-cache/        # Redis (future)
│   └── networking/           # VPC, subnets (future)
└── environments/         # Environment-specific configurations
    ├── dev/              # Development environment
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    ├── staging/          # Staging environment (future)
    └── production/       # Production environment (future)
```

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

- **Terraform** >= 1.10.0 ([Download](https://www.terraform.io/downloads))
- **GCP Account** with billing enabled
- **MongoDB Atlas Account** ([Sign up](https://www.mongodb.com/cloud/atlas/register))
- **GCP Service Account** with appropriate IAM roles:
  - `roles/container.admin` - For GKE cluster management
  - `roles/iam.serviceAccountUser` - For service account operations
  - `roles/compute.networkAdmin` - For network management
- **MongoDB Atlas API Keys** ([Create keys](https://docs.atlas.mongodb.com/configure-api-access/))

### Initial Setup

1. **Install Terraform**

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.10.0/terraform_1.10.0_linux_amd64.zip
unzip terraform_1.10.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

2. **Authenticate with GCP**

```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

3. **Configure MongoDB Atlas API Keys**

Create API keys in MongoDB Atlas:
- Go to Organization Settings > API Keys
- Create a new API key with "Organization Project Creator" permissions
- Save the public and private keys securely

### Deploy Development Environment

1. **Navigate to the development environment**

```bash
cd terraform/environments/dev
```

2. **Create your configuration file**

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. **Edit `terraform.tfvars` with your values**

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"

mongodb_atlas_project_id = "your-mongodb-atlas-project-id"
mongodb_username         = "app_user"

mongodb_ip_whitelist = [
  "YOUR_IP_ADDRESS/32"  # Replace with your IP
]
```

4. **Set sensitive variables via environment variables**

```bash
export TF_VAR_mongodb_atlas_public_key="your-public-key"
export TF_VAR_mongodb_atlas_private_key="your-private-key"
export TF_VAR_mongodb_password="your-secure-password"
```

5. **Initialize Terraform**

```bash
terraform init
```

This downloads required providers and prepares the backend.

6. **Review the execution plan**

```bash
terraform plan
```

Review all resources that will be created.

7. **Apply the configuration**

```bash
terraform apply
```

Type `yes` when prompted to confirm.

8. **Save the outputs**

```bash
terraform output -json > outputs.json
```

### Access Your Resources

#### Connect to GKE Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) \
  --region $(terraform output -raw gke_cluster_location) \
  --project YOUR_PROJECT_ID

# Verify connection
kubectl get nodes
```

#### Get MongoDB Connection String

```bash
# Get connection string (stored securely)
terraform output -raw mongodb_srv_connection_string

# Use in your application
mongodb+srv://username:password@cluster.mongodb.net/database
```

## 📚 Module Documentation

Each module has comprehensive documentation:

- [**kubernetes-cluster**](./modules/kubernetes-cluster/README.md) - GKE cluster provisioning
- [**managed-database**](./modules/managed-database/README.md) - MongoDB Atlas cluster

## 🔧 Common Operations

### Update Infrastructure

```bash
cd terraform/environments/dev

# See what will change
terraform plan

# Apply changes
terraform apply
```

### Upgrade Provider Versions

```bash
# Upgrade to latest compatible versions
terraform init -upgrade

# Review changes
terraform plan
```

### Destroy Infrastructure

```bash
cd terraform/environments/dev

# CAUTION: This will destroy all resources
terraform destroy
```

Always backup data before destroying production resources!

### Import Existing Resources

```bash
# Import existing GKE cluster
terraform import module.kubernetes_cluster.google_container_cluster.primary projects/PROJECT_ID/locations/REGION/clusters/CLUSTER_NAME

# Import existing MongoDB cluster
terraform import module.managed_database.mongodbatlas_cluster.main PROJECT_ID-CLUSTER_NAME
```

## 🔐 State Management

### Remote State Backend

This configuration uses Google Cloud Storage (GCS) for remote state:

```hcl
backend "gcs" {
  bucket = "saas-framework-terraform-state"
  prefix = "dev/terraform.tfstate"
}
```

### State Best Practices

1. **Never commit state files** to version control
2. **Use remote state** for team collaboration
3. **Enable state locking** to prevent concurrent modifications
4. **Backup state regularly** for disaster recovery
5. **Use separate state files** for different environments

### State Commands

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.kubernetes_cluster.google_container_cluster.primary

# Move resource in state
terraform state mv SOURCE DESTINATION

# Remove resource from state
terraform state rm RESOURCE
```

## 🎯 Best Practices

### 1. Code Organization

- ✅ Use modules for reusable components
- ✅ Separate environments into different directories
- ✅ Keep environment-specific values in `terraform.tfvars`
- ✅ Use `locals` for computed or repeated values
- ✅ Add validation rules to variables

### 2. Security

- ✅ Never commit secrets or credentials
- ✅ Use environment variables for sensitive data
- ✅ Mark sensitive outputs as `sensitive = true`
- ✅ Restrict state file access
- ✅ Use least-privilege IAM roles
- ✅ Enable audit logging

### 3. Versioning

- ✅ Pin provider versions using `~>` for compatibility
- ✅ Use required_version for Terraform
- ✅ Test upgrades in non-production first
- ✅ Document breaking changes

### 4. Testing

- ✅ Always run `terraform plan` before `apply`
- ✅ Use `terraform validate` to check syntax
- ✅ Review plan output carefully
- ✅ Test in development before production
- ✅ Use dry-run mode when available

### 5. Documentation

- ✅ Document all variables with descriptions
- ✅ Provide examples for each module
- ✅ Keep README files up to date
- ✅ Document any manual steps required
- ✅ Include troubleshooting guides

## 🛠️ Troubleshooting

### Common Issues

#### Issue: "Error: Backend initialization required"

**Solution**: Run `terraform init` to initialize the backend.

#### Issue: "Error: Insufficient permissions"

**Solution**: Verify your GCP service account has the required IAM roles:
```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:YOUR_SA_EMAIL"
```

#### Issue: "Error: State lock timeout"

**Solution**: Another user or process is modifying the state. Wait or force-unlock if necessary:
```bash
terraform force-unlock LOCK_ID
```

⚠️ Only force-unlock if you're certain no other process is running!

#### Issue: "Error: Provider version mismatch"

**Solution**: Update providers:
```bash
terraform init -upgrade
```

#### Issue: "Resource already exists"

**Solution**: Import the existing resource:
```bash
terraform import RESOURCE_ADDRESS RESOURCE_ID
```

### Getting Help

1. Check the [Terraform documentation](https://www.terraform.io/docs)
2. Review provider documentation:
   - [Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
   - [MongoDB Atlas Provider](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs)
3. Search [Terraform community forum](https://discuss.hashicorp.com/c/terraform-core)
4. Check module-specific README files

## 📊 Cost Estimation

### Development Environment

Estimated monthly costs:
- **GKE Cluster**: ~$150-200/month
  - Control plane: ~$75/month
  - 3x e2-standard-4 preemptible nodes: ~$75-125/month
- **MongoDB Atlas M10**: ~$60/month
- **Total**: ~$210-260/month

### Production Environment (Estimated)

Estimated monthly costs:
- **GKE Cluster**: ~$500-800/month
  - Control plane: ~$75/month
  - 5x n2-standard-8 nodes: ~$425-725/month
- **MongoDB Atlas M30**: ~$500/month
- **Total**: ~$1000-1300/month

💡 **Cost Optimization Tips**:
- Use preemptible VMs for non-production
- Enable auto-scaling to avoid over-provisioning
- Pause/delete unused resources
- Use committed use discounts for production
- Monitor with Google Cloud Billing

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.10.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/dev
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: terraform/environments/dev
        env:
          TF_VAR_mongodb_atlas_public_key: ${{ secrets.MONGODB_PUBLIC_KEY }}
          TF_VAR_mongodb_atlas_private_key: ${{ secrets.MONGODB_PRIVATE_KEY }}
```

## 📖 Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Google Cloud Terraform Modules](https://github.com/terraform-google-modules)
- [MongoDB Atlas with Terraform](https://www.mongodb.com/docs/atlas/tutorial/terraform-quickstart/)
- [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)

## 🤝 Contributing

When contributing to Terraform configurations:

1. Test changes in development environment first
2. Run `terraform fmt` to format code
3. Run `terraform validate` to check syntax
4. Update documentation for any new variables or modules
5. Include examples for new modules
6. Follow existing naming conventions

## 📝 License

See [LICENSE](../../LICENSE) file for details.
