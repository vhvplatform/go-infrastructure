# Managed Database Module (MongoDB Atlas)

This Terraform module provisions a MongoDB Atlas cluster on Google Cloud Platform with enterprise-grade features including high availability, automatic backups, and auto-scaling.

## Features

- **Multi-region Replication**: High availability with automatic failover
- **Automatic Backups**: Point-in-time recovery and continuous backups
- **Auto-scaling**: Automatic storage and compute scaling
- **Network Security**: IP whitelisting for access control
- **Monitoring & Alerts**: Built-in monitoring and alerting capabilities
- **Encryption**: Encryption at rest and in transit

## Architecture

```
┌──────────────────────────────────────────────┐
│      MongoDB Atlas Cluster                   │
│  ┌────────────┐  ┌────────────┐  ┌─────────┐│
│  │ Primary    │  │ Secondary  │  │Secondary││
│  │ (Electable)│  │(Electable) │  │(Read)   ││
│  └────────────┘  └────────────┘  └─────────┘│
│         Automatic Replication                │
│         Point-in-Time Recovery               │
│         Auto-scaling (Storage/Compute)       │
└──────────────────────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │  IP Whitelist        │
         │  (Access Control)    │
         └─────────────────────┘
```

## Usage

### Basic Example

```hcl
module "managed_database" {
  source = "../../modules/managed-database"
  
  project_id        = "mongodb-atlas-project-id"
  cluster_name      = "my-database"
  region            = "CENTRAL_US"
  instance_size     = "M10"
  database_name     = "myapp"
  database_username = "app_user"
  database_password = var.db_password
  
  ip_whitelist = ["10.0.0.0/8"]
}
```

### Production Example

```hcl
module "managed_database" {
  source = "../../modules/managed-database"
  
  project_id        = "mongodb-atlas-prod-project"
  cluster_name      = "production-database"
  region            = "CENTRAL_US"
  instance_size     = "M30"
  mongodb_version   = "7.0"
  
  # Database configuration
  database_name     = "production_db"
  database_username = var.db_username
  database_password = var.db_password
  
  # High availability configuration
  electable_nodes   = 3
  read_only_nodes   = 2
  
  # Backup configuration
  backup_enabled            = true
  pit_enabled               = true
  cloud_backup              = true
  
  # Auto-scaling configuration
  auto_scaling_disk_enabled    = true
  auto_scaling_compute_enabled = true
  
  # Network security
  ip_whitelist = [
    "10.0.0.0/8",     # Internal network
    "203.0.113.0/24"  # Office network
  ]
}
```

### Development Example

```hcl
module "managed_database" {
  source = "../../modules/managed-database"
  
  project_id        = "mongodb-atlas-dev-project"
  cluster_name      = "dev-database"
  region            = "CENTRAL_US"
  instance_size     = "M10"  # Minimum for dev
  
  database_name     = "dev_db"
  database_username = "dev_user"
  database_password = var.db_password
  
  electable_nodes   = 3
  
  # Minimal backup for dev
  backup_enabled            = true
  pit_enabled               = false  # Disable PIT for cost savings
  auto_scaling_disk_enabled = true
  auto_scaling_compute_enabled = false
  
  # Open access for development (NOT recommended for production)
  ip_whitelist = ["0.0.0.0/0"]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| mongodbatlas | ~> 1.21 |

## Providers

| Name | Version |
|------|---------|
| mongodbatlas | ~> 1.21 |

## Inputs

| Name | Description | Type | Default | Required | Validation |
|------|-------------|------|---------|----------|------------|
| project_id | MongoDB Atlas Project ID | `string` | n/a | yes | - |
| cluster_name | Name of the MongoDB cluster | `string` | n/a | yes | 1-64 chars, alphanumeric and hyphens only |
| region | GCP region | `string` | `"CENTRAL_US"` | no | - |
| instance_size | MongoDB instance size | `string` | `"M10"` | no | Must be valid Atlas tier (M10-M700) |
| mongodb_version | MongoDB major version | `string` | `"7.0"` | no | Must be valid version (4.4-7.0) |
| electable_nodes | Number of electable nodes | `number` | `3` | no | Must be odd number 3-50 |
| read_only_nodes | Number of read-only nodes | `number` | `0` | no | - |
| backup_enabled | Enable backups | `bool` | `true` | no | - |
| pit_enabled | Enable point-in-time recovery | `bool` | `true` | no | - |
| cloud_backup | Enable cloud backups | `bool` | `true` | no | - |
| auto_scaling_disk_enabled | Enable auto-scaling for disk | `bool` | `true` | no | - |
| auto_scaling_compute_enabled | Enable auto-scaling for compute | `bool` | `false` | no | - |
| database_name | Name of the database | `string` | n/a | yes | - |
| database_username | Database username | `string` | n/a | yes | - |
| database_password | Database password | `string` | n/a | yes | - |
| ip_whitelist | List of IP addresses to whitelist | `list(string)` | `[]` | no | - |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| cluster_id | MongoDB cluster ID | no |
| connection_string | Standard MongoDB connection string | yes |
| srv_connection_string | MongoDB SRV connection string (recommended) | yes |

## MongoDB Atlas Regions

Common GCP regions for MongoDB Atlas:

- `CENTRAL_US` - Iowa (us-central1)
- `EASTERN_US` - South Carolina (us-east1)
- `WESTERN_US` - Oregon (us-west1)
- `WESTERN_EUROPE` - Belgium (europe-west1)
- `EASTERN_ASIA_PACIFIC` - Taiwan (asia-east1)
- `NORTHEASTERN_ASIA_PACIFIC` - Tokyo (asia-northeast1)

[See full list of regions](https://www.mongodb.com/docs/atlas/reference/google-gcp/)

## Instance Sizes

| Tier | RAM | Storage | vCPUs | Use Case |
|------|-----|---------|-------|----------|
| M10 | 2 GB | 10 GB | Shared | Development, Testing |
| M20 | 4 GB | 20 GB | Shared | Small Production |
| M30 | 8 GB | 40 GB | 2 | Production |
| M40 | 16 GB | 80 GB | 4 | Medium Production |
| M50 | 32 GB | 160 GB | 8 | Large Production |
| M60 | 64 GB | 320 GB | 16 | Enterprise |

## Best Practices

### Security

1. **Restrict IP Whitelist**: Never use `0.0.0.0/0` in production. Only whitelist specific IPs or CIDR blocks.

2. **Strong Passwords**: Use strong, randomly generated passwords. Store them in a secure secret management system.

3. **Database Users**: Create separate database users for different applications with minimal required permissions.

4. **Enable Encryption**: MongoDB Atlas encrypts data at rest and in transit by default.

### High Availability

1. **Odd Number of Electable Nodes**: Always use an odd number (3, 5, 7) of electable nodes for proper replica set elections.

2. **Multi-region**: For critical applications, consider deploying electable nodes across multiple regions.

3. **Read-only Nodes**: Add read-only nodes to scale read operations without affecting the replica set voting.

### Performance

1. **Right-size Instances**: Start with M10 for development, M30+ for production. Monitor and adjust based on metrics.

2. **Enable Auto-scaling**: Enable both disk and compute auto-scaling for production clusters.

3. **Indexes**: Ensure proper indexing in your application. Use MongoDB Atlas Performance Advisor.

### Cost Optimization

1. **Development Clusters**: Use M10 instances and disable point-in-time recovery for dev/test environments.

2. **Auto-scaling**: Enable auto-scaling to avoid over-provisioning.

3. **Pause Clusters**: MongoDB Atlas allows pausing clusters for up to 30 days to save costs.

## Connection Strings

### Standard Connection String

```
mongodb://username:password@host1:27017,host2:27017,host3:27017/database?replicaSet=rs0
```

### SRV Connection String (Recommended)

```
mongodb+srv://username:password@cluster-name.mongodb.net/database
```

The SRV connection string is simpler and automatically discovers all cluster nodes.

## Troubleshooting

### Issue: Cannot connect to cluster

**Solutions**:
1. Verify IP address is in the whitelist
2. Check database username and password
3. Ensure cluster is not paused
4. Verify network connectivity

### Issue: Performance degradation

**Solutions**:
1. Check MongoDB Atlas metrics for resource utilization
2. Review slow queries in Performance Advisor
3. Ensure proper indexes are in place
4. Consider upgrading instance size or enabling auto-scaling

### Issue: High costs

**Solutions**:
1. Review actual resource usage vs provisioned
2. Enable auto-scaling to avoid over-provisioning
3. Consider smaller instance sizes for non-production
4. Disable point-in-time recovery for dev/test
5. Pause unused clusters

## Monitoring

MongoDB Atlas provides built-in monitoring:

- **Real-time Performance Panel**: View current operations, connections, and throughput
- **Metrics**: CPU, memory, disk, network, and database-specific metrics
- **Alerts**: Configure alerts for various conditions
- **Performance Advisor**: Recommendations for slow queries and missing indexes

Access monitoring via:
- MongoDB Atlas web interface
- Atlas API
- MongoDB Charts for custom dashboards

## Backup and Recovery

### Continuous Backups

- Automatic snapshots every 6 hours
- Retained based on your backup policy
- Point-in-time recovery available (if enabled)

### Point-in-Time Recovery

When enabled, allows restoration to any point within the last 24 hours.

### Restore Process

1. Navigate to cluster in Atlas
2. Select "Backup" tab
3. Choose snapshot or point-in-time
4. Restore to existing or new cluster

## Examples

See the `environments/` directory for complete examples:
- `environments/dev/` - Development environment configuration

## References

- [MongoDB Atlas Documentation](https://www.mongodb.com/docs/atlas/)
- [Terraform MongoDB Atlas Provider](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs)
- [MongoDB Atlas Best Practices](https://www.mongodb.com/docs/atlas/best-practices/)
- [MongoDB Security Checklist](https://www.mongodb.com/docs/manual/administration/security-checklist/)

## License

See [LICENSE](../../../LICENSE) file for details.
