terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.14"
    }
  }
}

resource "mongodbatlas_cluster" "main" {
  project_id = var.project_id
  name       = var.cluster_name
  
  # Provider Settings
  provider_name               = "GCP"
  provider_region_name        = var.region
  provider_instance_size_name = var.instance_size
  
  # Cluster configuration
  mongo_db_major_version = var.mongodb_version
  
  # Replication
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = var.region
      electable_nodes = var.electable_nodes
      priority        = 7
      read_only_nodes = var.read_only_nodes
    }
  }
  
  # Backup
  backup_enabled                     = var.backup_enabled
  pit_enabled                        = var.pit_enabled
  cloud_backup                       = var.cloud_backup
  auto_scaling_disk_gb_enabled       = var.auto_scaling_disk_enabled
  auto_scaling_compute_enabled       = var.auto_scaling_compute_enabled
  auto_scaling_compute_scale_down_enabled = var.auto_scaling_compute_enabled
}

resource "mongodbatlas_database_user" "main" {
  username           = var.database_username
  password           = var.database_password
  project_id         = var.project_id
  auth_database_name = "admin"
  
  roles {
    role_name     = "readWrite"
    database_name = var.database_name
  }
  
  roles {
    role_name     = "dbAdmin"
    database_name = var.database_name
  }
}

resource "mongodbatlas_project_ip_access_list" "main" {
  count      = length(var.ip_whitelist)
  project_id = var.project_id
  cidr_block = var.ip_whitelist[count.index]
  comment    = "IP whitelist for ${var.cluster_name}"
}
