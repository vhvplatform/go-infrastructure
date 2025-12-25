variable "project_id" {
  description = "GCP Project ID"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be between 6 and 30 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,38}[a-z0-9])?$", var.cluster_name))
    error_message = "The cluster_name must start with a letter, end with a letter or number, contain only lowercase letters, numbers, and hyphens, and be 1-40 characters long."
  }
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "VPC subnetwork name"
  type        = string
  default     = "default"
}

variable "pods_range_name" {
  description = "Secondary range name for pods"
  type        = string
  default     = "pods"
}

variable "services_range_name" {
  description = "Secondary range name for services"
  type        = string
  default     = "services"
}

variable "initial_node_count" {
  description = "Initial number of nodes in the cluster"
  type        = number
  default     = 3
  
  validation {
    condition     = var.initial_node_count >= 1 && var.initial_node_count <= 100
    error_message = "The initial_node_count must be between 1 and 100."
  }
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_node_count >= 0 && var.min_node_count <= 100
    error_message = "The min_node_count must be between 0 and 100."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_node_count >= 1 && var.max_node_count <= 1000
    error_message = "The max_node_count must be between 1 and 1000."
  }
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type"
  type        = string
  default     = "pd-standard"
}

variable "preemptible" {
  description = "Use preemptible nodes"
  type        = bool
  default     = false
}

variable "service_account" {
  description = "Service account for nodes"
  type        = string
  default     = ""
}

variable "node_labels" {
  description = "Labels for nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags for nodes"
  type        = list(string)
  default     = []
}

variable "authorized_networks" {
  description = "List of authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "maintenance_start_time" {
  description = "Maintenance window start time"
  type        = string
  default     = "03:00"
}

variable "release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
  
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "The release_channel must be one of: RAPID, REGULAR, STABLE."
  }
}
