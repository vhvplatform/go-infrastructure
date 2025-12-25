# Terraform Infrastructure

Infrastructure as Code using Terraform for provisioning cloud resources.

## Structure

```
terraform/
├── modules/              # Reusable modules
│   ├── kubernetes-cluster/   # GKE cluster
│   ├── managed-database/     # MongoDB Atlas
│   ├── managed-cache/        # Redis (future)
│   └── networking/           # VPC, subnets (future)
└── environments/         # Environment configs
    ├── dev/
    ├── staging/
    └── production/
```

## Prerequisites

- Terraform >= 1.5.0
- GCP account with billing enabled
- MongoDB Atlas account
- Service account credentials

## Usage

### Initialize

```bash
cd terraform/environments/dev
terraform init
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Destroy

```bash
terraform destroy
```

## Environment Variables

Set sensitive variables via environment:

```bash
export TF_VAR_mongodb_atlas_public_key="your-public-key"
export TF_VAR_mongodb_atlas_private_key="your-private-key"
export TF_VAR_mongodb_password="your-password"
```

## State Management

State is stored in GCS backend:

```hcl
terraform {
  backend "gcs" {
    bucket = "saas-framework-terraform-state"
    prefix = "dev/terraform.tfstate"
  }
}
```

## Best Practices

1. Always run `terraform plan` first
2. Use workspaces for isolation
3. Keep modules reusable
4. Document all variables
5. Never commit secrets
6. Use remote state
7. Tag all resources

## Modules

### kubernetes-cluster

Provisions GKE cluster with:
- Auto-scaling node pools
- Workload Identity
- VPC-native networking
- Release channels

### managed-database

Provisions MongoDB Atlas cluster with:
- Configurable instance size
- Auto-scaling
- Backups and PIT recovery
- IP whitelisting

## Adding Resources

1. Create module in `modules/`
2. Use in environment configs
3. Document in module README
4. Test in dev first
5. Promote to staging/prod
