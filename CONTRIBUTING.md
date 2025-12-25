# Contributing to go-infrastructure

Thank you for your interest in contributing to the go-infrastructure project! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Contribution Guidelines](#contribution-guidelines)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of background or experience level.

### Expected Behavior

- Be respectful and considerate
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Accept responsibility for mistakes

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling or insulting remarks
- Personal or political attacks
- Publishing others' private information

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Git** installed and configured
- **Kubectl** v1.27+ for Kubernetes manifests
- **Helm** v3.12+ for Helm charts
- **Terraform** v1.10+ for infrastructure code
- **Kustomize** v5.0+ for Kustomize overlays
- Access to a Kubernetes cluster for testing

### Fork and Clone

1. **Fork the repository** on GitHub

2. **Clone your fork**:
```bash
git clone https://github.com/YOUR_USERNAME/go-infrastructure.git
cd go-infrastructure
```

3. **Add upstream remote**:
```bash
git remote add upstream https://github.com/vhvcorp/go-infrastructure.git
```

4. **Keep your fork in sync**:
```bash
git fetch upstream
git checkout main
git merge upstream/main
```

## Development Workflow

### 1. Create a Branch

Always create a new branch for your changes:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or updates

### 2. Make Changes

- Follow the [Coding Standards](#coding-standards) below
- Keep changes focused and atomic
- Write clear, descriptive commit messages
- Test your changes thoroughly

### 3. Commit Your Changes

Write meaningful commit messages:

```bash
git add .
git commit -m "feat: add new monitoring dashboard for API service

- Add Grafana dashboard configuration
- Include metrics for response time and error rate
- Update documentation with dashboard usage"
```

Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Build/tooling changes

### 4. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Contribution Guidelines

### What to Contribute

We welcome contributions in these areas:

#### Infrastructure Code (Terraform)
- New Terraform modules
- Provider updates
- Bug fixes in existing modules
- Performance improvements

#### Kubernetes Manifests
- New service definitions
- Resource optimizations
- Security improvements
- Configuration updates

#### Helm Charts
- New charts
- Chart improvements
- Values file enhancements
- Template fixes

#### Documentation
- README improvements
- Architecture diagrams
- Troubleshooting guides
- Tutorial content

#### Monitoring & Observability
- New dashboards
- Alert rules
- Log aggregation configs
- Metric definitions

### Before You Start

1. **Check existing issues** - Someone might be working on it
2. **Open an issue** - Discuss major changes before implementing
3. **Review documentation** - Understand the project structure
4. **Test locally** - Verify your changes work

## Pull Request Process

### 1. Before Submitting

- [ ] Code follows project conventions
- [ ] All tests pass
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] Branch is up to date with main

### 2. PR Description

Include in your PR description:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (describe)

## Changes Made
- List key changes
- Include any breaking changes
- Mention related issues

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
```

### 3. Review Process

- Reviewers will be automatically assigned
- Address feedback promptly
- Make requested changes
- Re-request review after updates
- Be patient - reviews take time

### 4. Merging

Once approved:
- PRs will be merged by maintainers
- Squash and merge is preferred
- Delete branch after merge

## Coding Standards

### Terraform

#### File Organization

```
module/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider versions (optional)
├── locals.tf        # Local values (if needed)
└── README.md        # Module documentation
```

#### Formatting

```bash
# Format all Terraform files
terraform fmt -recursive
```

#### Naming Conventions

- **Resources**: Use descriptive names with underscores
  ```hcl
  resource "google_container_cluster" "primary_cluster" { }
  ```

- **Variables**: Use snake_case
  ```hcl
  variable "cluster_name" { }
  ```

- **Outputs**: Use descriptive names
  ```hcl
  output "cluster_endpoint" { }
  ```

#### Best Practices

```hcl
# ✅ Good: Use variables with validation
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ✅ Good: Add comments for complex logic
# This creates a cluster with VPC-native networking
# to improve pod-to-pod communication performance
resource "google_container_cluster" "primary" {
  # ...
}

# ✅ Good: Use locals for repeated values
locals {
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ❌ Bad: Hardcoded values
resource "google_container_cluster" "primary" {
  name = "my-cluster-dev"  # Use variables instead
}

# ❌ Bad: No descriptions
variable "name" {
  type = string
}
```

### Kubernetes Manifests

#### YAML Style

```yaml
# Use 2 spaces for indentation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
    version: v1.0.0
spec:
  replicas: 3
  # ...
```

#### Best Practices

- Always specify resource requests and limits
- Use namespaces appropriately
- Include labels for organization
- Add health checks (liveness/readiness probes)
- Use ConfigMaps and Secrets for configuration
- Follow the principle of least privilege

### Helm Charts

#### Chart Structure

```
chart/
├── Chart.yaml
├── values.yaml
├── values.dev.yaml
├── values.prod.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl
└── README.md
```

#### Values Files

```yaml
# Use meaningful defaults
replicaCount: 3

image:
  repository: myapp
  tag: "1.0.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

### Documentation

#### README Files

Every module/component should have a README with:

1. **Overview**: What it does
2. **Features**: Key capabilities
3. **Usage**: How to use it
4. **Requirements**: Dependencies
5. **Inputs/Outputs**: Parameters and results
6. **Examples**: Real-world usage
7. **Troubleshooting**: Common issues

#### Code Comments

```terraform
# Good comment: Explains WHY, not WHAT
# We use preemptible nodes in dev to reduce costs by ~70%
# This is acceptable since dev workloads can tolerate interruptions
preemptible = var.environment == "dev" ? true : false
```

#### Inline Documentation

Use descriptive variable descriptions:

```hcl
variable "cluster_name" {
  description = "Name of the GKE cluster. Must be unique within the project and region. Used in resource naming and tagging."
  type        = string
}
```

## Testing

### Terraform Testing

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Run in development first
cd terraform/environments/dev
terraform plan
```

### Kubernetes Manifests Testing

```bash
# Validate manifests
kubectl apply --dry-run=client -f manifest.yaml

# Validate with server
kubectl apply --dry-run=server -f manifest.yaml

# Test with Kustomize
kubectl apply -k overlays/dev --dry-run=server
```

### Helm Chart Testing

```bash
# Lint chart
helm lint charts/my-chart

# Validate template rendering
helm template my-release charts/my-chart

# Dry-run installation
helm install my-release charts/my-chart --dry-run --debug
```

## Documentation

### Writing Style

- Use clear, concise language
- Include examples
- Assume readers have basic knowledge
- Link to external resources
- Keep it up to date

### Documentation Types

1. **README files**: Overview and quick start
2. **Inline comments**: Explain complex logic
3. **Architecture diagrams**: Visual representations
4. **Troubleshooting guides**: Common issues and solutions
5. **API documentation**: For custom tools

## Questions?

If you have questions:

1. Check existing documentation
2. Search closed issues
3. Open a new issue with the `question` label
4. Join our Slack channel: #go-infrastructure

## Recognition

Contributors will be:
- Listed in release notes
- Mentioned in documentation
- Added to CONTRIBUTORS.md (if significant contributions)

Thank you for contributing! 🎉
