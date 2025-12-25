terraform {
  required_version = ">= 1.5.0"
  
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

module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"
  
  project_id         = var.project_id
  cluster_name       = "saas-framework-dev"
  region             = var.region
  initial_node_count = 3
  min_node_count     = 1
  max_node_count     = 5
  machine_type       = "e2-standard-4"
  disk_size_gb       = 100
  preemptible        = true
  
  node_labels = {
    environment = "development"
    managed-by  = "terraform"
  }
  
  node_tags = ["saas-dev"]
}

module "managed_database" {
  source = "../../modules/managed-database"
  
  project_id        = var.mongodb_atlas_project_id
  cluster_name      = "saas-dev"
  region            = "CENTRAL_US"
  instance_size     = "M10"
  database_name     = "saas_dev"
  database_username = var.mongodb_username
  database_password = var.mongodb_password
  electable_nodes   = 3
  
  backup_enabled            = true
  pit_enabled               = false
  auto_scaling_disk_enabled = true
  
  ip_whitelist = var.mongodb_ip_whitelist
}
