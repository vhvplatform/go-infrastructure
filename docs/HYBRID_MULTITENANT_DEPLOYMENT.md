# Hybrid Multi-tenant SaaS Architecture - Deployment Guide

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Development Deployment](#development-deployment)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Overview

This guide provides detailed instructions for deploying the Hybrid Multi-tenant SaaS infrastructure that supports two routing patterns:

1. **Pattern A (Subfolder)**: `saas.com/{tenant_id}/api/{service_name}/*`
2. **Pattern B (Custom Domain)**: `customer.com/api/{service_name}/*`

### Key Components

- **Nginx Ingress Controller**: Routes traffic based on patterns
- **Tenant Mapper Service**: Resolves custom domains to tenant IDs
- **Redis StatefulSet**: Stores domain mappings and session data
- **Microservices**: Backend services (auth, user, tenant, etc.)

## Architecture

See the architecture diagrams:
- [Overall Architecture](diagrams/architecture-overview.puml)
- [Traffic Flow - Pattern A](diagrams/traffic-flow-pattern-a.puml)
- [Traffic Flow - Pattern B](diagrams/traffic-flow-pattern-b.puml)

![Architecture Overview](diagrams/output/architecture-overview.png)

### Traffic Routing Flow

#### Pattern A: Subfolder-based Routing
```
Request: https://saas.com/tenant-123/api/users/profile
         ↓
    Nginx Ingress
         ↓
    Extract tenant_id = "tenant-123"
         ↓
    Inject X-Tenant-ID: tenant-123
         ↓
    Rewrite URI: /api/users/profile
         ↓
    Route to: user-service
         ↓
    Backend receives:
    - X-Tenant-ID: tenant-123
    - URI: /api/users/profile
```

#### Pattern B: Custom Domain Routing
```
Request: https://customer.com/api/users/profile
         ↓
    Nginx Ingress
         ↓
    Call auth-url: http://tenant-mapper
         ↓
    Tenant Mapper:
    - Reads X-Original-Host: customer.com
    - Queries Redis: domain:customer.com → tenant-456
    - Returns X-Tenant-ID: tenant-456
         ↓
    Nginx injects X-Tenant-ID: tenant-456
         ↓
    Route to: user-service
         ↓
    Backend receives:
    - X-Tenant-ID: tenant-456
    - URI: /api/users/profile
```

## Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| `kubectl` | v1.27+ | [Install](https://kubernetes.io/docs/tasks/tools/) |
| `helm` | v3.12+ | [Install](https://helm.sh/docs/intro/install/) |
| `kustomize` | v5.0+ | [Install](https://kubectl.docs.kubernetes.io/installation/kustomize/) |
| `docker` | v24+ | [Install](https://docs.docker.com/get-docker/) |
| `redis-cli` | Latest | `apt-get install redis-tools` |

### Infrastructure Requirements

**Development:**
- Kubernetes cluster (minikube, kind, or GKE)
- 4 CPU cores, 8GB RAM minimum
- 50GB storage

**Production:**
- GKE cluster (3+ nodes)
- n1-standard-4 or better
- 100GB+ SSD storage
- Load balancer support

### Access Requirements

- Kubernetes cluster access (kubeconfig configured)
- Container registry access (GCR or Docker Hub)
- DNS management access (for custom domains)
- TLS certificates (Let's Encrypt or custom)

## Development Deployment

### Step 1: Clone Repository

```bash
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure
```

### Step 2: Setup Local Kubernetes Cluster

#### Using Minikube

```bash
# Start minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=50g

# Enable required addons
minikube addons enable ingress
minikube addons enable storage-provisioner

# Verify cluster
kubectl cluster-info
```

#### Using kind

```bash
# Create cluster with ingress support
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Install Nginx Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Step 3: Create Namespace and Secrets

```bash
# Create namespace
kubectl create namespace saas-framework

# Create secrets
kubectl create secret generic saas-secrets \
  --namespace=saas-framework \
  --from-literal=mongodb-uri="mongodb://localhost:27017/saas" \
  --from-literal=redis-password="dev-redis-password" \
  --from-literal=jwt-secret="dev-jwt-secret-key" \
  --from-literal=rabbitmq-password="dev-rabbitmq-password"
```

### Step 4: Build Tenant Mapper Service

```bash
# Navigate to tenant-mapper directory
cd server/tenant-mapper

# Build Docker image
docker build -t tenant-mapper:dev .

# Load image to minikube (if using minikube)
minikube image load tenant-mapper:dev

# Or push to registry
# docker tag tenant-mapper:dev gcr.io/your-project/tenant-mapper:dev
# docker push gcr.io/your-project/tenant-mapper:dev
```

### Step 5: Deploy Infrastructure with Kustomize

```bash
# Deploy base infrastructure
kubectl apply -k kubernetes/base/

# Verify deployments
kubectl get pods -n saas-framework

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# redis-0                           1/1     Running   0          2m
# tenant-mapper-xxx                 1/1     Running   0          2m
# auth-service-xxx                  1/1     Running   0          2m
# user-service-xxx                  1/1     Running   0          2m
# ...
```

### Step 6: Configure Redis with Domain Mappings

```bash
# Port-forward Redis
kubectl port-forward -n saas-framework statefulset/redis 6379:6379 &

# Set Redis password
export REDIS_PASSWORD="dev-redis-password"

# Add domain mappings
redis-cli -a $REDIS_PASSWORD SET domain:customer.local tenant-123
redis-cli -a $REDIS_PASSWORD SET domain:acme.local tenant-456
redis-cli -a $REDIS_PASSWORD SET domain:demo.local tenant-789

# Verify mappings
redis-cli -a $REDIS_PASSWORD KEYS "domain:*"
```

### Step 7: Update /etc/hosts for Local Testing

```bash
# Add entries to /etc/hosts
sudo bash -c 'cat >> /etc/hosts <<EOF
127.0.0.1 saas.local
127.0.0.1 customer.local
127.0.0.1 acme.local
127.0.0.1 demo.local
EOF'
```

### Step 8: Test Routing Patterns

#### Test Pattern A (Subfolder)

```bash
# Get ingress IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test with tenant_id in path
curl -H "Host: saas.local" http://$INGRESS_IP/tenant-123/api/health

# Expected response: Should receive response with X-Tenant-ID header
```

#### Test Pattern B (Custom Domain)

```bash
# Test custom domain
curl -H "Host: customer.local" http://$INGRESS_IP/api/health

# Verify tenant-mapper logs
kubectl logs -n saas-framework -l app=tenant-mapper --tail=50

# Expected log: "Resolved domain customer.local to tenant: tenant-123"
```

### Step 9: Deploy Using Helm (Alternative)

```bash
# Install with Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework \
  --create-namespace

# Check status
helm status saas-platform -n saas-framework

# List releases
helm list -n saas-framework
```

## Production Deployment

### Step 1: Prepare GKE Cluster

```bash
# Set project and region
export PROJECT_ID="your-gcp-project"
export REGION="us-central1"
export CLUSTER_NAME="saas-platform-prod"

# Create GKE cluster
gcloud container clusters create $CLUSTER_NAME \
  --region $REGION \
  --num-nodes 3 \
  --machine-type n1-standard-4 \
  --disk-size 100 \
  --disk-type pd-ssd \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias \
  --network "default" \
  --subnetwork "default" \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# Verify connection
kubectl cluster-info
```

### Step 2: Install Nginx Ingress Controller

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Nginx Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"=true \
  --set controller.podAnnotations."prometheus\.io/port"=10254

# Wait for external IP
kubectl get service -n ingress-nginx ingress-nginx-controller --watch
```

### Step 3: Install cert-manager for TLS

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=90s

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Step 4: Create Production Secrets

```bash
# Create namespace
kubectl create namespace saas-framework-prod

# Generate secure passwords
export REDIS_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 64)
export RABBITMQ_PASSWORD=$(openssl rand -base64 32)
export MONGODB_URI="mongodb+srv://user:password@cluster.mongodb.net/saas?retryWrites=true&w=majority"

# Create secrets
kubectl create secret generic saas-secrets \
  --namespace=saas-framework-prod \
  --from-literal=mongodb-uri="$MONGODB_URI" \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --from-literal=jwt-secret="$JWT_SECRET" \
  --from-literal=rabbitmq-password="$RABBITMQ_PASSWORD"

# Save passwords securely (use secret manager in production)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env.prod.backup
echo "JWT_SECRET=$JWT_SECRET" >> .env.prod.backup
echo "RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD" >> .env.prod.backup
```

### Step 5: Build and Push Container Images

```bash
# Build tenant-mapper
cd server/tenant-mapper
docker build -t gcr.io/$PROJECT_ID/tenant-mapper:1.0.0 .
docker push gcr.io/$PROJECT_ID/tenant-mapper:1.0.0

# Tag as latest
docker tag gcr.io/$PROJECT_ID/tenant-mapper:1.0.0 gcr.io/$PROJECT_ID/tenant-mapper:latest
docker push gcr.io/$PROJECT_ID/tenant-mapper:latest

cd ../..
```

### Step 6: Update Production Manifests

```bash
# Update image references in overlays/prod
cat > kubernetes/overlays/prod/tenant-mapper-patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-mapper
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: tenant-mapper
        image: gcr.io/$PROJECT_ID/tenant-mapper:1.0.0
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF
```

### Step 7: Deploy to Production

```bash
# Option 1: Using Kustomize
kubectl apply -k kubernetes/overlays/prod/

# Option 2: Using Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.prod.yaml \
  --namespace saas-framework-prod \
  --create-namespace \
  --wait \
  --timeout 10m

# Verify deployment
kubectl get pods -n saas-framework-prod
kubectl get ingress -n saas-framework-prod
```

### Step 8: Configure DNS

```bash
# Get ingress external IP
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Configure DNS records:"
echo "A    saas.yourdomain.com    $EXTERNAL_IP"
echo "A    *.yourdomain.com       $EXTERNAL_IP"
echo ""
echo "Or use wildcard:"
echo "A    *.yourdomain.com       $EXTERNAL_IP"
```

### Step 9: Load Domain Mappings to Redis

```bash
# Port-forward Redis (production)
kubectl port-forward -n saas-framework-prod statefulset/redis 6379:6379 &

# Set Redis password
export REDIS_PASSWORD="<your-prod-redis-password>"

# Load production domain mappings
redis-cli -a $REDIS_PASSWORD <<EOF
SET domain:customer1.com tenant-a1b2c3
SET domain:customer2.com tenant-d4e5f6
SET domain:acmecorp.com tenant-g7h8i9
EOF

# Verify
redis-cli -a $REDIS_PASSWORD KEYS "domain:*"
```

### Step 10: Verify Production Deployment

```bash
# Check all pods are running
kubectl get pods -n saas-framework-prod

# Check ingress
kubectl get ingress -n saas-framework-prod

# Test Pattern A
curl https://saas.yourdomain.com/tenant-a1b2c3/api/health

# Test Pattern B
curl https://customer1.com/api/health

# Check logs
kubectl logs -n saas-framework-prod -l app=tenant-mapper --tail=100
```

## Configuration

### Environment Variables

#### Tenant Mapper Service

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `REDIS_ADDR` | Redis server address | `redis:6379` | Yes |
| `REDIS_PASSWORD` | Redis password | - | Yes |

#### Backend Services

All backend services should read the `X-Tenant-ID` header:

```go
// Example in Go
tenantID := r.Header.Get("X-Tenant-ID")
if tenantID == "" {
    http.Error(w, "Tenant ID required", http.StatusBadRequest)
    return
}
```

### Redis Key Format

Domain mappings are stored in Redis with the following format:

```
Key: domain:{hostname}
Value: {tenant_id}

Examples:
domain:customer1.com → tenant-abc123
domain:acmecorp.com → tenant-xyz789
```

### Ingress Configuration

#### Pattern A Configuration

Edit `kubernetes/base/ingress/ingress-pattern-a-subfolder.yaml`:

```yaml
spec:
  rules:
  - host: saas.yourdomain.com  # Change to your domain
```

#### Pattern B Configuration

Edit `kubernetes/base/ingress/ingress-pattern-b-custom-domain.yaml`:

```yaml
spec:
  rules:
  - host: "*.yourdomain.com"  # Change to your wildcard domain
```

## Testing

### Unit Testing

```bash
# Test tenant-mapper locally
cd server/tenant-mapper
go test -v ./...
```

### Integration Testing

```bash
# Test full workflow
./scripts/test-routing.sh dev

# Test specific pattern
./scripts/test-pattern-a.sh
./scripts/test-pattern-b.sh
```

### Load Testing

```bash
# Install hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Test Pattern A
hey -n 1000 -c 10 -H "Host: saas.local" \
  http://$INGRESS_IP/tenant-123/api/health

# Test Pattern B
hey -n 1000 -c 10 -H "Host: customer.local" \
  http://$INGRESS_IP/api/health
```

## Troubleshooting

### Common Issues

#### 1. Tenant Mapper Returns 401

**Problem**: Custom domain requests return 401 Unauthorized.

**Solution**:
```bash
# Check if domain is in Redis
kubectl port-forward -n saas-framework statefulset/redis 6379:6379
redis-cli -a $REDIS_PASSWORD GET domain:customer.com

# If not found, add it
redis-cli -a $REDIS_PASSWORD SET domain:customer.com tenant-123
```

#### 2. Pattern A Not Extracting Tenant ID

**Problem**: Backend services don't receive X-Tenant-ID header.

**Solution**:
```bash
# Check ingress annotations
kubectl get ingress -n saas-framework saas-multi-tenant-subfolder -o yaml

# Verify nginx configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep tenant
```

#### 3. Redis Connection Failed

**Problem**: Tenant mapper can't connect to Redis.

**Solution**:
```bash
# Check Redis is running
kubectl get pods -n saas-framework -l app=redis

# Check Redis service
kubectl get svc -n saas-framework redis

# Test Redis connection
kubectl run redis-test --rm -it --image=redis:7-alpine -- redis-cli -h redis.saas-framework.svc.cluster.local -a $REDIS_PASSWORD ping
```

#### 4. DNS Not Resolving

**Problem**: Custom domains don't resolve.

**Solution**:
```bash
# Verify DNS records
nslookup customer.com
dig customer.com

# Check ingress external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Update DNS to point to external IP
```

### Debug Commands

```bash
# View tenant-mapper logs
kubectl logs -n saas-framework -l app=tenant-mapper -f

# Check ingress events
kubectl get events -n saas-framework --sort-by='.lastTimestamp'

# Describe ingress
kubectl describe ingress -n saas-framework

# Check nginx ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f

# Test from within cluster
kubectl run curl-test --rm -it --image=curlimages/curl -- sh
# curl http://tenant-mapper.saas-framework.svc.cluster.local -H "X-Original-Host: customer.com"
```

### Monitoring

```bash
# Port-forward Prometheus
kubectl port-forward -n saas-framework svc/prometheus 9090:9090

# Port-forward Grafana
kubectl port-forward -n saas-framework svc/grafana 3000:3000

# View metrics
open http://localhost:9090  # Prometheus
open http://localhost:3000  # Grafana
```

## Next Steps

1. Set up monitoring and alerting
2. Configure backup strategy for Redis
3. Implement rate limiting per tenant
4. Add custom metrics for tenant usage
5. Set up log aggregation with Loki
6. Configure horizontal pod autoscaling

## Additional Resources

- [Nginx Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Multi-tenancy Best Practices](https://kubernetes.io/docs/concepts/security/multi-tenancy/)

## Support

For issues or questions:
- Create an issue in the repository
- Contact: team@saas-framework.io
- Slack: #go-infrastructure
