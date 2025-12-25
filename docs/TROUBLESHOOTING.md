# Troubleshooting Guide

Common issues and solutions for the SaaS Platform infrastructure.

## Pods Not Starting

### ImagePullBackOff

**Symptom**: Pod stuck in `ImagePullBackOff` state

**Causes**:
- Image doesn't exist
- Wrong image tag
- Missing image pull secrets
- Registry authentication failed

**Solutions**:
```bash
# Check image exists
docker pull ghcr.io/longvhv/saas-auth-service:dev

# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token> \
  -n saas-framework-dev

# Patch deployment to use secret
kubectl patch deployment auth-service \
  -n saas-framework-dev \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ghcr-secret"}]}}}}'
```

### CrashLoopBackOff

**Symptom**: Pod keeps restarting

**Solutions**:
```bash
# Check logs
kubectl logs <pod-name> -n saas-framework-dev --previous

# Check events
kubectl describe pod <pod-name> -n saas-framework-dev

# Common fixes:
# 1. Check environment variables
# 2. Verify secrets exist
# 3. Check database connectivity
# 4. Review resource limits
```

## Deployment Issues

### Stuck Deployment

**Symptom**: Deployment not progressing

```bash
# Check deployment status
kubectl rollout status deployment/<name> -n saas-framework-dev

# View deployment events
kubectl describe deployment/<name> -n saas-framework-dev

# Force restart
kubectl rollout restart deployment/<name> -n saas-framework-dev
```

## Service Issues

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n saas-framework-dev

# Check pod labels match service selector
kubectl get pods --show-labels -n saas-framework-dev
kubectl get svc <service-name> -o yaml -n saas-framework-dev

# Test service internally
kubectl run test --rm -it --image=busybox -n saas-framework-dev -- sh
wget -O- http://<service-name>:8080/health
```

## Resource Issues

### Out of Memory (OOM)

```bash
# Check memory usage
kubectl top pods -n saas-framework-dev

# Increase memory limits
kubectl patch deployment <name> -n saas-framework-dev \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"<name>","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

## Monitoring Issues

### Metrics Not Appearing

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n saas-framework-dev

# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n saas-framework
# Open http://localhost:9090/targets

# Verify service has metrics port
kubectl get svc <service-name> -o yaml -n saas-framework-dev
```

## ArgoCD Issues

### Application Out of Sync

```bash
# View diff
argocd app diff <app-name>

# Sync manually
argocd app sync <app-name>

# Hard refresh
argocd app get <app-name> --hard-refresh
```

## Quick Debugging Commands

```bash
# Get all resources in namespace
kubectl get all -n saas-framework-dev

# Check recent events
kubectl get events --sort-by='.lastTimestamp' -n saas-framework-dev | tail -20

# Check pod logs
kubectl logs -f -n saas-framework-dev -l app=<service-name>

# Execute into pod
kubectl exec -it <pod-name> -n saas-framework-dev -- sh

# Check resource usage
kubectl top nodes
kubectl top pods -n saas-framework-dev
```
