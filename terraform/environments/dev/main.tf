terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.21"
    }
  }
  
  backend "gcs" {
    bucket = "saas-framework-terraform-state"
    prefix = "dev/terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

# ============================================================================
# Local Values
# ============================================================================
# Define common values and computed configurations here to avoid repetition
# and ensure consistency across resources
# ============================================================================

locals {
  environment = "dev"
  project_name = "saas-framework"
  
  # Common tags for resource management and cost allocation
  common_labels = {
    environment = local.environment
    managed_by  = "terraform"
    project     = local.project_name
  }
  
  # Naming conventions
  cluster_name  = "${local.project_name}-${local.environment}"
  database_name = "${local.project_name}_${local.environment}"
}

# ============================================================================
# GKE Cluster Module
# ============================================================================
# Provisions a Google Kubernetes Engine cluster for the development environment
# ============================================================================

module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id         = var.project_id
  cluster_name       = local.cluster_name
  region             = var.region
  initial_node_count = 3
  min_node_count     = 1
  max_node_count     = 5
  machine_type       = "e2-standard-4"
  disk_size_gb       = 100
  preemptible        = true  # Use preemptible VMs for cost savings in dev
  
  node_labels = merge(
    local.common_labels,
    {
      tier = "standard"
    }
  )
  
  node_tags = ["${local.project_name}-${local.environment}"]
}

# ============================================================================
# MongoDB Atlas Cluster Module
# ============================================================================
# Provisions a managed MongoDB database cluster
# ============================================================================

module "managed_database" {
  source = "../../modules/managed-database"
  
  project_id        = var.mongodb_atlas_project_id
  cluster_name      = "${local.project_name}-${local.environment}"
  region            = "CENTRAL_US"
  instance_size     = "M10"  # Smallest production tier
  database_name     = local.database_name
  database_username = var.mongodb_username
  database_password = var.mongodb_password
  electable_nodes   = 3      # Minimum for high availability
  
  # Backup configuration
  backup_enabled            = true
  pit_enabled               = false  # Point-in-time recovery disabled for dev
  auto_scaling_disk_enabled = true   # Enable automatic storage scaling
  
  ip_whitelist = var.mongodb_ip_whitelist
}
