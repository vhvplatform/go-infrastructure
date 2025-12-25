terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ============================================================================
# GKE Cluster Configuration
# ============================================================================
# This module creates a Google Kubernetes Engine (GKE) cluster with:
# - VPC-native networking for optimized pod-to-pod communication
# - Separate managed node pools for flexibility
# - Workload Identity for secure service account authentication
# - Auto-scaling capabilities for cost optimization
# ============================================================================

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.network
  subnetwork = var.subnetwork
  
  # VPC-native networking enables IP aliasing and improves network performance
  networking_mode = "VPC_NATIVE"
  
  # IP allocation for pods and services using secondary IP ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  
  # Control plane access - restrict which networks can access the cluster API
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  # Maintenance window configuration - minimize disruption during updates
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }
  
  # Workload Identity enables pods to authenticate as GCP service accounts
  # This is more secure than using node service accounts
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Release channel determines the cadence of cluster upgrades
  # RAPID: Weekly, REGULAR: Every few weeks, STABLE: Every few months
  release_channel {
    channel = var.release_channel
  }
  
  # Essential cluster addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
}

# ============================================================================
# Node Pool Configuration
# ============================================================================
# Separate node pool allows independent scaling and upgrades without
# affecting the control plane
# ============================================================================

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.initial_node_count
  
  # Enable auto-scaling to handle variable workloads efficiently
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  # Auto-repair and auto-upgrade ensure nodes stay healthy and up-to-date
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = var.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = var.node_labels
    tags   = var.node_tags
    
    # Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Disable legacy metadata endpoints for improved security
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
