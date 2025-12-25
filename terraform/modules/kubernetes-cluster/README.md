# Kubernetes Cluster Module

This Terraform module provisions a Google Kubernetes Engine (GKE) cluster with best practices for security, scalability, and maintainability.

## Features

- **VPC-Native Networking**: Optimized pod-to-pod communication using IP aliasing
- **Workload Identity**: Secure service account authentication for pods
- **Auto-scaling**: Automatic node scaling based on workload demands
- **Auto-repair & Auto-upgrade**: Automated cluster maintenance
- **Separate Node Pools**: Independent scaling and upgrades without control plane disruption
- **Release Channels**: Choose between RAPID, REGULAR, or STABLE update cadence
- **Master Authorized Networks**: Control plane access restrictions

## Architecture

```
┌─────────────────────────────────────────┐
│         GKE Cluster (Control Plane)     │
│  - VPC-Native Networking                │
│  - Workload Identity Enabled            │
│  - Master Authorized Networks           │
└─────────────────┬───────────────────────┘
                  │
         ┌────────┴────────┐
         │   Node Pool      │
         │  - Auto-scaling  │
         │  - Auto-repair   │
         │  - Auto-upgrade  │
         └──────────────────┘
```

## Usage

### Basic Example

```hcl
module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id   = "my-gcp-project"
  cluster_name = "my-cluster"
  region       = "us-central1"
  
  initial_node_count = 3
  min_node_count     = 1
  max_node_count     = 10
  machine_type       = "e2-standard-4"
}
```

### Production Example

```hcl
module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id   = "production-project"
  cluster_name = "prod-cluster"
  region       = "us-central1"
  
  # Network configuration
  network           = "vpc-prod"
  subnetwork        = "subnet-prod-us-central1"
  pods_range_name   = "pods-range"
  services_range_name = "services-range"
  
  # Node pool configuration
  initial_node_count = 5
  min_node_count     = 3
  max_node_count     = 20
  machine_type       = "n2-standard-8"
  disk_size_gb       = 200
  disk_type          = "pd-ssd"
  preemptible        = false
  
  # Security
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Corporate Network"
    }
  ]
  
  # Maintenance
  maintenance_start_time = "03:00"
  release_channel        = "STABLE"
  
  # Labels and tags
  node_labels = {
    environment = "production"
    managed_by  = "terraform"
    team        = "platform"
  }
  
  node_tags = ["prod-cluster", "gke-node"]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| google | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required | Validation |
|------|-------------|------|---------|----------|------------|
| project_id | GCP Project ID | `string` | n/a | yes | Must be 6-30 chars, lowercase letters, numbers, hyphens |
| cluster_name | Name of the GKE cluster | `string` | n/a | yes | 1-40 chars, start with letter, lowercase letters, numbers, hyphens |
| region | GCP region for the cluster | `string` | `"us-central1"` | no | - |
| network | VPC network name | `string` | `"default"` | no | - |
| subnetwork | VPC subnetwork name | `string` | `"default"` | no | - |
| pods_range_name | Secondary range name for pods | `string` | `"pods"` | no | - |
| services_range_name | Secondary range name for services | `string` | `"services"` | no | - |
| initial_node_count | Initial number of nodes | `number` | `3` | no | Must be 1-100 |
| min_node_count | Minimum number of nodes | `number` | `1` | no | Must be 0-100 |
| max_node_count | Maximum number of nodes | `number` | `10` | no | Must be 1-1000 |
| machine_type | Machine type for nodes | `string` | `"e2-standard-4"` | no | - |
| disk_size_gb | Disk size in GB | `number` | `100` | no | - |
| disk_type | Disk type | `string` | `"pd-standard"` | no | - |
| preemptible | Use preemptible nodes | `bool` | `false` | no | - |
| service_account | Service account for nodes | `string` | `""` | no | - |
| node_labels | Labels for nodes | `map(string)` | `{}` | no | - |
| node_tags | Network tags for nodes | `list(string)` | `[]` | no | - |
| authorized_networks | List of authorized networks | `list(object)` | `[]` | no | - |
| maintenance_start_time | Maintenance window start time | `string` | `"03:00"` | no | - |
| release_channel | GKE release channel | `string` | `"REGULAR"` | no | Must be RAPID, REGULAR, or STABLE |

## Outputs

- `cluster_name` - The name of the cluster
- `cluster_endpoint` - The endpoint of the cluster (sensitive)
- `cluster_ca_certificate` - The CA certificate of the cluster (sensitive)
- `cluster_location` - The location of the cluster
- `node_pool_name` - The name of the node pool

## Best Practices

### Security

1. **Use Workload Identity**: This module enables Workload Identity by default. Configure your pods to use GCP service accounts.

2. **Restrict Master Access**: Use `authorized_networks` to limit which networks can access the cluster API.

3. **Use Custom Service Accounts**: Provide a custom service account via the `service_account` variable.

### Scalability

1. **Enable Auto-scaling**: Configure appropriate `min_node_count` and `max_node_count` values based on your workload.

2. **Choose the Right Machine Type**: 
   - CPU-intensive: `n2-highcpu-*`
   - Memory-intensive: `n2-highmem-*`
   - Balanced: `n2-standard-*`
   - Cost-optimized: `e2-standard-*`

3. **Use Preemptible VMs**: For non-production, enable `preemptible = true` to reduce costs.

### Reliability

1. **Release Channels**: 
   - Use `STABLE` for production
   - Use `REGULAR` for staging
   - Use `RAPID` for development

2. **Maintenance Windows**: Configure `maintenance_start_time` during low-traffic periods.

## Troubleshooting

### Issue: Cluster creation fails with "insufficient permissions"

Ensure the service account has these IAM roles:
- `roles/container.admin`
- `roles/iam.serviceAccountUser`
- `roles/compute.networkAdmin`

### Issue: Pods cannot authenticate with GCP services

Ensure Workload Identity is properly configured:
1. Enable Workload Identity (done by this module)
2. Create a GCP service account
3. Bind Kubernetes SA to GCP SA
4. Annotate Kubernetes SA with GCP SA email

## References

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
