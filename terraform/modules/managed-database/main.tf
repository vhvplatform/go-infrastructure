terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.21"
    }
  }
}

# ============================================================================
# MongoDB Atlas Cluster Configuration
# ============================================================================
# This module provisions a managed MongoDB Atlas cluster with:
# - Multi-region replication for high availability
# - Automatic backups with point-in-time recovery
# - Auto-scaling for storage and compute resources
# - Network security with IP whitelisting
# ============================================================================

resource "mongodbatlas_cluster" "main" {
  project_id = var.project_id
  name       = var.cluster_name
  
  # Cloud provider configuration - using GCP
  provider_name               = "GCP"
  provider_region_name        = var.region
  provider_instance_size_name = var.instance_size
  
  # MongoDB version - ensure compatibility with application requirements
  mongo_db_major_version = var.mongodb_version
  
  # Replication configuration for high availability
  # Electable nodes participate in elections and can become primary
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = var.region
      electable_nodes = var.electable_nodes
      priority        = 7  # Higher priority for primary election
      read_only_nodes = var.read_only_nodes
    }
  }
  
  # Backup configuration - critical for data protection
  backup_enabled                     = var.backup_enabled
  pit_enabled                        = var.pit_enabled  # Point-in-time recovery
  cloud_backup                       = var.cloud_backup
  
  # Auto-scaling configuration - optimize costs and performance
  auto_scaling_disk_gb_enabled       = var.auto_scaling_disk_enabled
  auto_scaling_compute_enabled       = var.auto_scaling_compute_enabled
  auto_scaling_compute_scale_down_enabled = var.auto_scaling_compute_enabled
}

# ============================================================================
# Database User Configuration
# ============================================================================
# Creates a database user with appropriate permissions
# ============================================================================

resource "mongodbatlas_database_user" "main" {
  username           = var.database_username
  password           = var.database_password
  project_id         = var.project_id
  auth_database_name = "admin"
  
  # Grant readWrite permissions for application operations
  roles {
    role_name     = "readWrite"
    database_name = var.database_name
  }
  
  # Grant dbAdmin permissions for database management
  roles {
    role_name     = "dbAdmin"
    database_name = var.database_name
  }
}

# ============================================================================
# Network Security Configuration
# ============================================================================
# IP Access List restricts which IPs can connect to the cluster
# This is a critical security measure to prevent unauthorized access
# ============================================================================

resource "mongodbatlas_project_ip_access_list" "main" {
  count      = length(var.ip_whitelist)
  project_id = var.project_id
  cidr_block = var.ip_whitelist[count.index]
  comment    = "IP whitelist for ${var.cluster_name}"
}
