# Kubernetes Cluster Module

This module provisions a Google Kubernetes Engine (GKE) cluster with best practices.

## Features

- VPC-native networking
- Workload Identity enabled
- Autoscaling node pools
- Automatic node repair and upgrade
- Customizable machine types and disk sizes
- Master authorized networks support
- Maintenance window configuration

## Usage

```hcl
module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id         = "my-project"
  cluster_name       = "saas-framework-dev"
  region             = "us-central1"
  initial_node_count = 3
  min_node_count     = 1
  max_node_count     = 10
  machine_type       = "e2-standard-4"
  disk_size_gb       = 100
}
```

## Requirements

- Terraform >= 1.5.0
- Google Cloud Provider ~> 5.0

## Inputs

See `variables.tf` for all available inputs.

## Outputs

- `cluster_name` - The name of the cluster
- `cluster_endpoint` - The endpoint of the cluster
- `cluster_ca_certificate` - The CA certificate of the cluster
- `cluster_location` - The location of the cluster
- `node_pool_name` - The name of the node pool
