output "cluster_id" {
  description = "MongoDB cluster ID"
  value       = mongodbatlas_cluster.main.id
}

output "connection_string" {
  description = "MongoDB connection string"
  value       = mongodbatlas_cluster.main.connection_strings[0].standard
  sensitive   = true
}

output "srv_connection_string" {
  description = "MongoDB SRV connection string"
  value       = mongodbatlas_cluster.main.connection_strings[0].standard_srv
  sensitive   = true
}
