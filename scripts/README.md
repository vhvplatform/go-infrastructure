# Scripts

Automation scripts for deployment and management.

## Available Scripts

### deploy.sh

Deploy infrastructure to specified environment.

```bash
./scripts/deploy.sh <environment> [method]

# Examples:
./scripts/deploy.sh dev kustomize
./scripts/deploy.sh staging helm
./scripts/deploy.sh production argocd
```

**Arguments:**
- `environment` - dev, staging, or production
- `method` - kustomize (default), helm, or argocd

### validate-manifests.sh

Validate Kubernetes and Helm manifests.

```bash
./scripts/validate-manifests.sh <environment>

# Example:
./scripts/validate-manifests.sh dev
```

Validates:
- Kustomize builds
- kubectl dry-run
- kubeval (if installed)
- Helm lint

### rollback.sh

Rollback deployments to previous revision.

```bash
./scripts/rollback.sh <environment> <revision>

# Examples:
./scripts/rollback.sh production 1  # Rollback to previous
./scripts/rollback.sh production 3  # Rollback to revision 3
```

### secrets-mgmt.sh

Manage Kubernetes secrets.

```bash
# Create secrets from template
./scripts/secrets-mgmt.sh dev create

# Update a secret value
./scripts/secrets-mgmt.sh dev update JWT_SECRET "new-value"

# View secret keys
./scripts/secrets-mgmt.sh dev view

# View specific secret
./scripts/secrets-mgmt.sh dev view JWT_SECRET

# Delete secrets
./scripts/secrets-mgmt.sh dev delete
```

## Prerequisites

All scripts require:
- `kubectl` configured with cluster access
- Appropriate KUBECONFIG or context set

Individual script requirements:
- `deploy.sh` - kubectl, kustomize, or helm
- `validate-manifests.sh` - kustomize, kubeval (optional), helm (optional)
- `rollback.sh` - kubectl
- `secrets-mgmt.sh` - kubectl, jq

## Making Scripts Executable

```bash
chmod +x scripts/*.sh
```

## Adding New Scripts

1. Create script in `scripts/` directory
2. Add shebang: `#!/bin/bash`
3. Add error handling: `set -e`
4. Make executable: `chmod +x`
5. Document in this README
6. Test thoroughly before committing
