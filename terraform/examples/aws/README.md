# AWS EKS Example Configuration

This directory contains an example Terraform configuration for deploying the SaaS platform infrastructure on AWS EKS.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.10.0
- kubectl installed

## Quick Start

### 1. Configure Variables

Create a `terraform.tfvars` file:

```hcl
region             = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

kubernetes_version = "1.28"

desired_node_count = 3
min_node_count     = 1
max_node_count     = 10
instance_types     = ["t3.medium"]

allowed_cidr_blocks = ["YOUR_IP/32"]  # Restrict to your IP
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 3. Configure kubectl

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name saas-framework-dev
```

### 4. Verify Deployment

```bash
# Check cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# Deploy workloads
kubectl apply -k ../../../kubernetes/overlays/dev
```

## Architecture

This example creates:

- **VPC** with public and private subnets across 2 AZs
- **Internet Gateway** for public subnet internet access
- **NAT Gateway** for private subnet internet access
- **EKS Cluster** in private subnets
- **Managed Node Group** with auto-scaling
- **IAM Roles** for cluster and nodes with IRSA support

## Customization

### Using Existing VPC

If you already have a VPC, modify `main.tf` to reference existing subnets:

```hcl
module "eks_cluster" {
  source = "../../modules/kubernetes-cluster-aws"
  
  cluster_name = "saas-framework-dev"
  subnet_ids   = ["subnet-xxx", "subnet-yyy"]
  # ... other variables
}
```

### Multiple Node Groups

Add additional node groups for different workload types:

```hcl
resource "aws_eks_node_group" "spot" {
  cluster_name    = module.eks_cluster.cluster_id
  node_group_name = "spot-nodes"
  # ... configure spot instances
  
  capacity_type = "SPOT"
}
```

## Cost Optimization

- Use spot instances for non-critical workloads
- Enable cluster autoscaler
- Use smaller instance types for development
- Delete NAT Gateway when not in use (dev environments)

## Security Best Practices

1. **Network**: Use private subnets for worker nodes
2. **Access**: Restrict `allowed_cidr_blocks` to known IPs
3. **Secrets**: Use AWS Secrets Manager or Parameter Store
4. **RBAC**: Configure Kubernetes RBAC for access control
5. **Audit**: Enable CloudWatch logging for the control plane

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

**Note**: Ensure all Kubernetes resources are deleted before destroying the cluster to avoid orphaned AWS resources.

## Next Steps

- Configure storage classes for EBS volumes
- Set up AWS Load Balancer Controller
- Configure external-dns for Route53 integration
- Set up cert-manager for TLS certificates
- Deploy monitoring stack (Prometheus/Grafana)
