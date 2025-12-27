# AWS EKS Kubernetes Cluster Module

This Terraform module provisions an Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups.

## Features

- **EKS Cluster**: Fully managed Kubernetes control plane
- **Managed Node Groups**: Auto-scaling worker nodes
- **IAM Roles for Service Accounts (IRSA)**: Secure pod-level IAM authentication
- **VPC Integration**: Multi-AZ deployment for high availability
- **Security**: Private endpoint access, security groups, and IAM policies
- **Logging**: Control plane logging to CloudWatch

## Usage

```hcl
module "eks_cluster" {
  source = "../../modules/kubernetes-cluster-aws"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.28"
  
  subnet_ids = [
    "subnet-12345678",
    "subnet-87654321",
  ]

  desired_node_count = 3
  min_node_count     = 1
  max_node_count     = 10
  instance_types     = ["t3.medium"]
  
  endpoint_private_access = true
  endpoint_public_access  = true
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

- `aws_eks_cluster` - EKS cluster
- `aws_eks_node_group` - Managed node group
- `aws_iam_role` - IAM roles for cluster and nodes
- `aws_iam_openid_connect_provider` - OIDC provider for IRSA

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| subnet_ids | List of subnet IDs | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.28"` | no |
| desired_node_count | Desired number of nodes | `number` | `3` | no |
| min_node_count | Minimum number of nodes | `number` | `1` | no |
| max_node_count | Maximum number of nodes | `number` | `10` | no |
| instance_types | EC2 instance types | `list(string)` | `["t3.medium"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The EKS cluster ID |
| cluster_endpoint | Endpoint for the EKS control plane |
| cluster_oidc_issuer_url | OIDC issuer URL for IRSA |

## Post-deployment

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```
