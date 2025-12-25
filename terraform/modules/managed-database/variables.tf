variable "project_id" {
  description = "MongoDB Atlas Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the MongoDB cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.cluster_name))
    error_message = "The cluster_name must be 1-64 characters, start and end with alphanumeric characters, and contain only alphanumeric characters and hyphens."
  }
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
  
  validation {
    condition     = can(regex("^M(10|20|30|40|50|60|80|140|200|300|400|700)$", var.instance_size))
    error_message = "The instance_size must be a valid MongoDB Atlas cluster tier (M10, M20, M30, M40, M50, M60, M80, M140, M200, M300, M400, M700)."
  }
}

variable "mongodb_version" {
  description = "MongoDB major version"
  type        = string
  default     = "7.0"
  
  validation {
    condition     = can(regex("^[4-7]\\.[0-9]+$", var.mongodb_version))
    error_message = "The mongodb_version must be a valid version (e.g., 4.4, 5.0, 6.0, 7.0)."
  }
}

variable "electable_nodes" {
  description = "Number of electable nodes"
  type        = number
  default     = 3
  
  validation {
    condition     = var.electable_nodes >= 3 && var.electable_nodes <= 50 && var.electable_nodes % 2 == 1
    error_message = "The electable_nodes must be an odd number between 3 and 50 for proper replica set voting."
  }
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
