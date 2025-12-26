# Hybrid Multi-tenant SaaS Architecture - Examples and Use Cases

## Overview

This document provides practical examples for implementing and using the hybrid multi-tenant SaaS architecture.

## Table of Contents

- [Setup Examples](#setup-examples)
- [Domain Mapping Examples](#domain-mapping-examples)
- [Backend Service Integration](#backend-service-integration)
- [Testing Examples](#testing-examples)
- [Monitoring Examples](#monitoring-examples)

## Setup Examples

### Example 1: Development Setup with Minikube

```bash
# Start minikube
minikube start --cpus=4 --memory=8192 --disk-size=50g
minikube addons enable ingress

# Deploy infrastructure
cd /path/to/go-infrastructure
./scripts/deploy-multitenant.sh dev kustomize

# Add local domain mappings to /etc/hosts
echo "$(minikube ip) saas.local customer.local acme.local" | sudo tee -a /etc/hosts

# Configure Redis with test tenants
kubectl port-forward -n saas-framework statefulset/redis 6379:6379 &
export REDIS_PASSWORD="dev-redis-password"

redis-cli -a $REDIS_PASSWORD SET domain:customer.local tenant-abc123
redis-cli -a $REDIS_PASSWORD SET domain:acme.local tenant-xyz789
```

### Example 2: Production Setup on GKE

```bash
# Create GKE cluster
export PROJECT_ID="my-saas-project"
export REGION="us-central1"

gcloud container clusters create saas-prod \
  --region $REGION \
  --num-nodes 3 \
  --machine-type n1-standard-4 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10

# Deploy with Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.prod.yaml \
  --namespace saas-framework-prod \
  --create-namespace

# Configure DNS
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Configure these DNS records:"
echo "A  saas.yourdomain.com  $EXTERNAL_IP"
echo "A  *.yourdomain.com     $EXTERNAL_IP"
```

## Domain Mapping Examples

### Example 1: Adding a New Customer Domain

```bash
# Port-forward Redis
kubectl port-forward -n saas-framework-prod statefulset/redis 6379:6379 &

# Get Redis password
REDIS_PASSWORD=$(kubectl get secret -n saas-framework-prod saas-secrets -o jsonpath='{.data.redis-password}' | base64 -d)

# Add customer domain mapping
redis-cli -a $REDIS_PASSWORD SET domain:customer1.com tenant-c1-001
redis-cli -a $REDIS_PASSWORD SET domain:www.customer1.com tenant-c1-001
redis-cli -a $REDIS_PASSWORD SET domain:customer1.co.uk tenant-c1-001

# Verify
redis-cli -a $REDIS_PASSWORD GET domain:customer1.com
# Output: tenant-c1-001
```

### Example 2: Bulk Import Domain Mappings

```bash
# Create a CSV file with domain mappings
cat > domains.csv <<EOF
customer1.com,tenant-c1-001
customer2.com,tenant-c2-002
acme.com,tenant-acme-003
demo.com,tenant-demo-004
EOF

# Import to Redis
kubectl port-forward -n saas-framework-prod statefulset/redis 6379:6379 &
REDIS_PASSWORD=$(kubectl get secret -n saas-framework-prod saas-secrets -o jsonpath='{.data.redis-password}' | base64 -d)

while IFS=, read -r domain tenant_id; do
  redis-cli -a $REDIS_PASSWORD SET "domain:$domain" "$tenant_id"
  echo "Added: $domain -> $tenant_id"
done < domains.csv

# Verify all mappings
redis-cli -a $REDIS_PASSWORD KEYS "domain:*"
```

### Example 3: Managing Domain Mappings with a Script

```bash
#!/bin/bash
# domain-manager.sh - Manage domain to tenant mappings

REDIS_PASSWORD="${REDIS_PASSWORD:-$(kubectl get secret -n saas-framework-prod saas-secrets -o jsonpath='{.data.redis-password}' | base64 -d)}"

add_domain() {
  local domain=$1
  local tenant_id=$2
  redis-cli -a $REDIS_PASSWORD SET "domain:$domain" "$tenant_id"
  echo "✓ Added: $domain -> $tenant_id"
}

remove_domain() {
  local domain=$1
  redis-cli -a $REDIS_PASSWORD DEL "domain:$domain"
  echo "✓ Removed: $domain"
}

list_domains() {
  redis-cli -a $REDIS_PASSWORD --scan --pattern "domain:*" | while read key; do
    domain=${key#domain:}
    tenant_id=$(redis-cli -a $REDIS_PASSWORD GET "$key")
    echo "$domain -> $tenant_id"
  done
}

get_tenant() {
  local domain=$1
  redis-cli -a $REDIS_PASSWORD GET "domain:$domain"
}

# Usage examples:
# add_domain customer.com tenant-123
# remove_domain customer.com
# list_domains
# get_tenant customer.com
```

## Backend Service Integration

### Example 1: Go Service with Tenant ID Extraction

```go
// middleware/tenant.go
package middleware

import (
    "context"
    "net/http"
)

type contextKey string

const TenantIDKey contextKey = "tenant_id"

// TenantMiddleware extracts X-Tenant-ID header and adds to context
func TenantMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        tenantID := r.Header.Get("X-Tenant-ID")
        
        if tenantID == "" {
            http.Error(w, "X-Tenant-ID header required", http.StatusBadRequest)
            return
        }
        
        // Add tenant ID to request context
        ctx := context.WithValue(r.Context(), TenantIDKey, tenantID)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

// GetTenantID retrieves tenant ID from context
func GetTenantID(ctx context.Context) (string, bool) {
    tenantID, ok := ctx.Value(TenantIDKey).(string)
    return tenantID, ok
}

// Usage in handler:
func GetUserHandler(w http.ResponseWriter, r *http.Request) {
    tenantID, ok := GetTenantID(r.Context())
    if !ok {
        http.Error(w, "Tenant ID not found", http.StatusInternalServerError)
        return
    }
    
    // Query database with tenant isolation
    user, err := db.GetUser(tenantID, userID)
    // ...
}
```

### Example 2: Database Query with Tenant Isolation (MongoDB)

```go
// repository/user_repository.go
package repository

import (
    "context"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/mongo"
)

type UserRepository struct {
    collection *mongo.Collection
}

func (r *UserRepository) FindByID(ctx context.Context, tenantID, userID string) (*User, error) {
    var user User
    
    // Always include tenant_id in query for tenant isolation
    filter := bson.M{
        "tenant_id": tenantID,
        "_id":       userID,
    }
    
    err := r.collection.FindOne(ctx, filter).Decode(&user)
    if err != nil {
        return nil, err
    }
    
    return &user, nil
}

func (r *UserRepository) Create(ctx context.Context, tenantID string, user *User) error {
    // Always set tenant_id when creating records
    user.TenantID = tenantID
    
    _, err := r.collection.InsertOne(ctx, user)
    return err
}

func (r *UserRepository) List(ctx context.Context, tenantID string, limit, offset int64) ([]*User, error) {
    var users []*User
    
    // Always filter by tenant_id
    filter := bson.M{"tenant_id": tenantID}
    
    opts := options.Find().
        SetLimit(limit).
        SetSkip(offset)
    
    cursor, err := r.collection.Find(ctx, filter, opts)
    if err != nil {
        return nil, err
    }
    defer cursor.Close(ctx)
    
    if err = cursor.All(ctx, &users); err != nil {
        return nil, err
    }
    
    return users, nil
}
```

### Example 3: Node.js Express Service

```javascript
// middleware/tenant.js
const tenantMiddleware = (req, res, next) => {
  const tenantId = req.headers['x-tenant-id'];
  
  if (!tenantId) {
    return res.status(400).json({
      error: 'X-Tenant-ID header is required'
    });
  }
  
  // Attach to request object
  req.tenantId = tenantId;
  next();
};

// Usage in routes
app.use('/api', tenantMiddleware);

app.get('/api/users/:id', async (req, res) => {
  const { tenantId } = req;
  const { id } = req.params;
  
  // Query with tenant isolation
  const user = await User.findOne({
    tenant_id: tenantId,
    _id: id
  });
  
  res.json(user);
});
```

## Testing Examples

### Example 1: Test Pattern A (Subfolder Routing)

```bash
# Test with curl
INGRESS_IP=$(minikube ip)

# Test health endpoint
curl -H "Host: saas.local" \
  http://$INGRESS_IP/tenant-123/api/health

# Test with tenant isolation
curl -H "Host: saas.local" \
  -H "Authorization: Bearer ${TOKEN}" \
  http://$INGRESS_IP/tenant-123/api/users/me

# Verify tenant ID is extracted correctly
kubectl logs -n saas-framework -l app=api-gateway --tail=20 | grep "X-Tenant-ID"
```

### Example 2: Test Pattern B (Custom Domain Routing)

```bash
# Test with curl
INGRESS_IP=$(minikube ip)

# Test health endpoint
curl -H "Host: customer.local" \
  http://$INGRESS_IP/api/health

# Test authenticated endpoint
curl -H "Host: customer.local" \
  -H "Authorization: Bearer ${TOKEN}" \
  http://$INGRESS_IP/api/users/me

# Verify tenant-mapper resolved domain correctly
kubectl logs -n saas-framework -l app=tenant-mapper --tail=20
```

### Example 3: Load Testing

```bash
# Install hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Load test Pattern A
hey -n 10000 -c 100 -q 10 \
  -H "Host: saas.local" \
  -H "Authorization: Bearer ${TOKEN}" \
  http://$(minikube ip)/tenant-123/api/users

# Load test Pattern B
hey -n 10000 -c 100 -q 10 \
  -H "Host: customer.local" \
  -H "Authorization: Bearer ${TOKEN}" \
  http://$(minikube ip)/api/users

# Monitor performance
kubectl top pods -n saas-framework
```

## Monitoring Examples

### Example 1: Check Tenant Mapper Health

```bash
# Check pod status
kubectl get pods -n saas-framework -l app=tenant-mapper

# Check logs
kubectl logs -n saas-framework -l app=tenant-mapper -f

# Test health endpoint directly
kubectl port-forward -n saas-framework svc/tenant-mapper 8080:80 &
curl http://localhost:8080/health
curl http://localhost:8080/ready
```

### Example 2: Monitor Redis Performance

```bash
# Port-forward Redis
kubectl port-forward -n saas-framework statefulset/redis 6379:6379 &

# Get Redis info
redis-cli -a $REDIS_PASSWORD INFO

# Monitor commands in real-time
redis-cli -a $REDIS_PASSWORD MONITOR

# Check memory usage
redis-cli -a $REDIS_PASSWORD INFO memory

# Check key statistics
redis-cli -a $REDIS_PASSWORD DBSIZE
redis-cli -a $REDIS_PASSWORD --scan --pattern "domain:*" | wc -l
```

### Example 3: Prometheus Metrics Query

```bash
# Port-forward Prometheus
kubectl port-forward -n saas-framework svc/prometheus 9090:9090 &

# Open Prometheus UI
open http://localhost:9090

# Example PromQL queries:

# Request rate by tenant (if instrumented)
rate(http_requests_total{tenant_id="tenant-123"}[5m])

# Tenant mapper response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="tenant-mapper"}[5m]))

# Redis connection pool
redis_connected_clients

# Ingress request rate
rate(nginx_ingress_controller_requests[5m])
```

### Example 4: Grafana Dashboard

```bash
# Port-forward Grafana
kubectl port-forward -n saas-framework svc/grafana 3000:3000 &

# Open Grafana
open http://localhost:3000

# Import dashboard for multi-tenant metrics
# Dashboard JSON available at: docs/monitoring/grafana-dashboard-multitenant.json
```

## Advanced Examples

### Example 1: Blue-Green Deployment for Tenant Mapper

```bash
# Deploy new version (blue)
kubectl set image deployment/tenant-mapper \
  -n saas-framework \
  tenant-mapper=gcr.io/project/tenant-mapper:v2.0.0

# Monitor rollout
kubectl rollout status deployment/tenant-mapper -n saas-framework

# Test new version
./scripts/test-pattern-b.sh

# Rollback if issues detected
kubectl rollout undo deployment/tenant-mapper -n saas-framework
```

### Example 2: Tenant Migration

```bash
# Scenario: Move tenant from one ID to another

# Step 1: Update domain mapping
redis-cli -a $REDIS_PASSWORD SET domain:customer.com tenant-new-456

# Step 2: Verify new mapping
redis-cli -a $REDIS_PASSWORD GET domain:customer.com

# Step 3: Test access
curl -H "Host: customer.com" http://$INGRESS_IP/api/health

# Step 4: Migrate data in database (application-specific)
# kubectl exec -it mongo-pod -- mongo
# db.users.updateMany({tenant_id: "tenant-old-123"}, {$set: {tenant_id: "tenant-new-456"}})

# Step 5: Remove old mapping if no longer needed
# redis-cli -a $REDIS_PASSWORD DEL domain:old-customer.com
```

### Example 3: Multi-region Setup

```yaml
# values-us.yaml
ingress:
  patternB:
    hosts:
      - "*.us.yourdomain.com"
tenantMapper:
  redisAddr: "redis-us:6379"

# values-eu.yaml
ingress:
  patternB:
    hosts:
      - "*.eu.yourdomain.com"
tenantMapper:
  redisAddr: "redis-eu:6379"
```

```bash
# Deploy to US region
helm upgrade --install saas-platform-us helm/charts/saas-platform \
  -f helm/charts/saas-platform/values-us.yaml \
  --kube-context=gke-us-central1

# Deploy to EU region
helm upgrade --install saas-platform-eu helm/charts/saas-platform \
  -f helm/charts/saas-platform/values-eu.yaml \
  --kube-context=gke-europe-west1
```

## Troubleshooting Examples

### Example 1: Debug Tenant Resolution Issues

```bash
# Check if domain exists in Redis
kubectl port-forward -n saas-framework statefulset/redis 6379:6379 &
redis-cli -a $REDIS_PASSWORD GET domain:customer.com

# Check tenant-mapper logs
kubectl logs -n saas-framework -l app=tenant-mapper --tail=50

# Test tenant-mapper directly
kubectl run test-pod --rm -it --image=curlimages/curl -- sh
curl -H "X-Original-Host: customer.com" http://tenant-mapper.saas-framework.svc.cluster.local
```

### Example 2: Debug Ingress Routing

```bash
# Check ingress configuration
kubectl get ingress -n saas-framework -o yaml

# Check nginx controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f

# Describe ingress for events
kubectl describe ingress -n saas-framework saas-multi-tenant-custom-domain

# Test from within cluster
kubectl run debug-pod --rm -it --image=curlimages/curl -- sh
curl -H "Host: customer.local" http://api-gateway.saas-framework.svc.cluster.local:8080/api/health
```

## Best Practices

1. **Always validate tenant ID**: Every API endpoint should verify the X-Tenant-ID header
2. **Database isolation**: Always include tenant_id in database queries
3. **Monitoring**: Track metrics per tenant for usage and billing
4. **Redis backups**: Regular backups of domain mappings
5. **Rate limiting**: Implement per-tenant rate limiting
6. **Logging**: Include tenant ID in all log entries
7. **Security**: Validate that users can only access their tenant's data

## Conclusion

These examples demonstrate the flexibility and power of the hybrid multi-tenant SaaS architecture. For more details, see the [complete deployment guide](HYBRID_MULTITENANT_DEPLOYMENT.md).
