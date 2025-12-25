# Infrastructure Repository Extraction Guide

Guide for extracting the infrastructure directory to a separate `go-infrastructure` repository.

## Overview

This guide helps you extract the `infrastructure/` directory from the monorepo into its own repository while preserving git history.

## Prerequisites

- `git-filter-repo` installed: `pip install git-filter-repo`
- GitHub CLI installed (optional): `gh` command
- Admin access to GitHub organization

## Step 1: Create New Repository

### Option A: Via GitHub UI
1. Go to https://github.com/new
2. Repository name: `go-infrastructure`
3. Description: "Infrastructure as Code for SaaS Platform"
4. Visibility: Private (recommended)
5. Do NOT initialize with README
6. Click "Create repository"

### Option B: Via GitHub CLI
```bash
gh repo create vhvcorp/go-infrastructure \
  --private \
  --description "Infrastructure as Code for SaaS Platform"
```

## Step 2: Extract Infrastructure with Git History

```bash
# Clone the monorepo to a new directory
git clone https://github.com/vhvcorp/go-framework.git go-infrastructure
cd go-infrastructure

# Filter to only infrastructure directory and move to root
git filter-repo --path infrastructure/ --path-rename infrastructure/:

# Verify the extraction
ls -la
# You should see: kubernetes/, helm/, terraform/, argocd/, monitoring/, scripts/, docs/, etc.
```

## Step 3: Update Repository Configuration

```bash
# Add new remote
git remote add origin https://github.com/vhvcorp/go-infrastructure.git

# Push to new repository
git push -u origin main

# Create develop branch
git checkout -b develop
git push -u origin develop
```

## Step 4: Update References

### Update Image References

All Kubernetes manifests need updated image references:

```bash
# Find all deployment files
find kubernetes/ -name "*.yaml" -type f

# Update image references (example)
# FROM: image: services/auth-service
# TO: image: ghcr.io/vhvcorp/go-auth-service:latest
```

### Update ArgoCD Source Repository

Edit `argocd/applications/*//*.yaml`:

```yaml
# Change repoURL from monorepo to infrastructure repo
spec:
  source:
    repoURL: https://github.com/vhvcorp/go-infrastructure  # Updated
    targetRevision: main
```

## Step 5: Configure GitHub Secrets

Set up deployment secrets in the new repository:

```bash
# Via GitHub CLI
gh secret set KUBECONFIG_DEV -b "$(cat ~/.kube/config-dev)"
gh secret set KUBECONFIG_STAGING -b "$(cat ~/.kube/config-staging)"
gh secret set KUBECONFIG_PROD -b "$(cat ~/.kube/config-prod)"

# Terraform secrets (if using)
gh secret set TF_VAR_mongodb_atlas_public_key -b "your-public-key"
gh secret set TF_VAR_mongodb_atlas_private_key -b "your-private-key"
```

### Required Secrets

- `KUBECONFIG_DEV` - Kubeconfig for dev cluster
- `KUBECONFIG_STAGING` - Kubeconfig for staging cluster
- `KUBECONFIG_PROD` - Kubeconfig for production cluster
- `TF_VAR_*` - Terraform variables (if using Terraform)
- `MONGODB_ATLAS_PUBLIC_KEY` - MongoDB Atlas API key
- `MONGODB_ATLAS_PRIVATE_KEY` - MongoDB Atlas API secret

## Step 6: Enable GitHub Actions

1. Go to repository Settings → Actions → General
2. Enable "Allow all actions and reusable workflows"
3. Set workflow permissions to "Read and write permissions"
4. Save changes

## Step 7: Configure Branch Protection

```bash
# Via GitHub CLI
gh api repos/vhvcorp/go-infrastructure/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["validate-k8s","validate-helm"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}'
```

Or via UI:
1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Require pull request reviews: 1 approval
4. Require status checks: validate-k8s, validate-helm
5. Save changes

## Step 8: Set Up ArgoCD Integration

### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Add Repository to ArgoCD

```bash
# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# Login to ArgoCD
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD

# Add repository
argocd repo add https://github.com/vhvcorp/go-infrastructure \
  --username <github-username> \
  --password <github-token>

# Deploy app-of-apps
kubectl apply -f argocd/app-of-apps.yaml
```

## Step 9: Update Monorepo

In the original monorepo:

1. Keep `infrastructure/` directory for reference
2. Add README.md pointing to new repo:

```markdown
# Infrastructure

Infrastructure configurations have been moved to:
https://github.com/vhvcorp/go-infrastructure

This directory is kept for reference during migration.
```

3. Update CI/CD to reference new repository
4. Update documentation links

## Step 10: Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Verify deployments in each environment
kubectl get pods -n saas-framework-dev
kubectl get pods -n saas-framework-staging
kubectl get pods -n saas-framework-prod

# Check GitHub Actions
gh run list --repo vhvcorp/go-infrastructure
```

## Post-Migration Checklist

- [ ] New repository created
- [ ] Git history preserved
- [ ] All references updated
- [ ] GitHub secrets configured
- [ ] GitHub Actions enabled
- [ ] Branch protection enabled
- [ ] ArgoCD configured
- [ ] Deployments verified
- [ ] Team access granted
- [ ] Documentation updated
- [ ] Monorepo references updated

## Rollback Plan

If issues occur:

1. Revert ArgoCD to point to monorepo
2. Keep both repositories active temporarily
3. Fix issues in new repository
4. Re-enable after verification

## Support

For issues during extraction:
- Create issue in monorepo
- Contact: team@saas-framework.io
- Slack: #infrastructure

## References

- [git-filter-repo Documentation](https://github.com/newren/git-filter-repo)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
