# GitOps Workflow

Guide to GitOps practices for the SaaS Platform infrastructure.

## Overview

GitOps uses Git as the single source of truth for declarative infrastructure and applications.

## Principles

1. **Declarative** - Everything is described declaratively
2. **Versioned** - All changes tracked in Git
3. **Automated** - Changes automatically applied
4. **Auditable** - Complete audit trail
5. **Self-healing** - Auto-sync to desired state

## Workflow

### Development
1. Create feature branch from `main`
2. Make infrastructure changes
3. Validate locally: `./scripts/validate-manifests.sh dev`
4. Create Pull Request
5. CI validates manifests
6. After approval, merge to `main`
7. Auto-deploys to dev environment

### Staging
1. Create release branch: `release/v1.x`
2. Test thoroughly in dev first
3. Merge to release branch
4. Auto-deploys to staging
5. Run smoke tests
6. Monitor for issues

### Production
1. Tag release: `git tag v1.0.0`
2. Trigger manual deployment workflow
3. Requires approval
4. Deployed via GitHub Actions
5. Health checks run
6. Monitor closely

## ArgoCD Management

```bash
# View applications
argocd app list

# Sync application
argocd app sync go-infrastructure-dev

# View sync status
argocd app get go-infrastructure-dev

# View diff
argocd app diff go-infrastructure-dev

# Rollback
argocd app rollback go-infrastructure-dev <revision>
```

## Best Practices

1. **Small, frequent changes** - Easier to review and rollback
2. **Test in lower environments first** - Dev → Staging → Prod
3. **Use Pull Requests** - Code review for infrastructure
4. **Descriptive commit messages** - Explain what and why
5. **Tag releases** - Use semantic versioning
6. **Monitor deployments** - Watch metrics and logs
7. **Document changes** - Update CHANGELOG.md
