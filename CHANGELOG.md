# Changelog

All notable changes to the SaaS Infrastructure will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Hybrid Multi-tenant SaaS Architecture (2024-12-26)
- **Tenant Mapper Service**: Go microservice for resolving custom domains to tenant IDs
  - Redis integration for domain mapping lookups
  - Health and readiness endpoints
  - Dockerfile and Kubernetes manifests
  - Service documentation with usage examples
  
- **Redis StatefulSet**: Converted Redis from Deployment to StatefulSet
  - Persistent volume claims for data persistence
  - ConfigMap for Redis configuration
  - Headless service for StatefulSet pods
  - Support for centralized sessions and domain mappings
  
- **Dual-Pattern Ingress Routing**:
  - **Pattern A (Subfolder)**: `saas.com/{tenant_id}/api/{service}/*`
    - Automatic tenant ID extraction from URI
    - X-Tenant-ID header injection
    - URI rewriting to remove tenant prefix
  - **Pattern B (Custom Domain)**: `customer.com/api/{service}/*`
    - Integration with tenant-mapper via nginx auth-url
    - Domain-based tenant resolution
    - Session cookie configuration with Path=/
  
- **Helm Charts Enhancements**:
  - Infrastructure chart templates for Redis StatefulSet, ConfigMap, and tenant-mapper
  - Saas-platform chart ingress templates for both routing patterns
  - Configurable values for multi-tenant architecture
  - Helper templates for labels and naming conventions
  
- **Comprehensive Documentation**:
  - English deployment guide (18KB) with step-by-step instructions
  - Vietnamese deployment guide (18KB) - full translation
  - Examples and use cases document (14KB) with practical scenarios
  - PlantUML architecture diagrams:
    - Overall architecture overview
    - Traffic flow for Pattern A (subfolder routing)
    - Traffic flow for Pattern B (custom domain routing)
    - CI/CD deployment flow
  
- **Automation Scripts**:
  - `deploy-multitenant.sh`: Automated deployment for hybrid architecture
  - `test-pattern-a.sh`: Validation script for subfolder routing
  - `test-pattern-b.sh`: Validation script for custom domain routing
  - Support for both Kustomize and Helm deployment methods
  
- **Repository Updates**:
  - Updated README with multi-tenant architecture overview
  - Enhanced .gitignore for Go build artifacts
  - Improved documentation structure and navigation

#### Initial Infrastructure
- Initial infrastructure repository structure
- Kubernetes manifests with Kustomize base and overlays
- Helm charts for saas-platform, infrastructure, and microservices
- Terraform modules for GKE cluster and managed databases
- ArgoCD applications for GitOps deployments
- Prometheus, Grafana, and Loki monitoring configurations
- ServiceMonitors for all microservices
- Deployment, validation, rollback, and secrets management scripts
- GitHub Actions workflows for validation and deployment
- Comprehensive documentation (DEPLOYMENT, EXTRACTION_GUIDE, etc.)
- Environment-specific configurations (dev, staging, production)
- Pod Disruption Budgets for production
- Horizontal Pod Autoscalers
- Alert rules for services and infrastructure

### Changed
- **Redis Infrastructure**: Migrated from Deployment to StatefulSet for data persistence
- **Ingress Configuration**: Enhanced to support dynamic tenant routing patterns
- **Documentation**: Restructured with dedicated multi-tenant guides and bilingual support

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- Secrets template added (not containing actual secrets)
- Image pull policies configured
- Resource limits applied

## [1.0.0] - TBD

Initial release after extraction from monorepo.
