variable "project_id" {
  description = "MongoDB Atlas Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the MongoDB cluster"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "CENTRAL_US"
}

variable "instance_size" {
  description = "MongoDB instance size (M10, M20, M30, etc.)"
  type        = string
  default     = "M10"
}

variable "mongodb_version" {
  description = "MongoDB major version"
  type        = string
  default     = "7.0"
}

variable "electable_nodes" {
  description = "Number of electable nodes"
  type        = number
  default     = 3
}

variable "read_only_nodes" {
  description = "Number of read-only nodes"
  type        = number
  default     = 0
}

variable "backup_enabled" {
  description = "Enable backups"
  type        = bool
  default     = true
}

variable "pit_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "cloud_backup" {
  description = "Enable cloud backups"
  type        = bool
  default     = true
}

variable "auto_scaling_disk_enabled" {
  description = "Enable auto-scaling for disk"
  type        = bool
  default     = true
}

variable "auto_scaling_compute_enabled" {
  description = "Enable auto-scaling for compute"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "ip_whitelist" {
  description = "List of IP addresses to whitelist"
  type        = list(string)
  default     = []
}
