# ============================================================================
# Development Environment Outputs
# ============================================================================
# These outputs provide important information about the provisioned resources
# Use them to configure applications and CI/CD pipelines
# ============================================================================

# GKE Cluster Outputs
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.kubernetes_cluster.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = module.kubernetes_cluster.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.kubernetes_cluster.cluster_location
}

output "gke_cluster_ca_certificate" {
  description = "The cluster CA certificate for kubectl configuration"
  value       = module.kubernetes_cluster.cluster_ca_certificate
  sensitive   = true
}

output "gke_node_pool_name" {
  description = "The name of the GKE node pool"
  value       = module.kubernetes_cluster.node_pool_name
}

# MongoDB Atlas Outputs
output "mongodb_cluster_id" {
  description = "The MongoDB Atlas cluster ID"
  value       = module.managed_database.cluster_id
}

output "mongodb_connection_string" {
  description = "Standard MongoDB connection string"
  value       = module.managed_database.connection_string
  sensitive   = true
}

output "mongodb_srv_connection_string" {
  description = "MongoDB SRV connection string (recommended)"
  value       = module.managed_database.srv_connection_string
  sensitive   = true
}

# General Information
output "environment" {
  description = "Environment name"
  value       = "dev"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.kubernetes_cluster.cluster_name} --region ${module.kubernetes_cluster.cluster_location} --project ${var.project_id}"
}
