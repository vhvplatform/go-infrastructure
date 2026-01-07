# Scalable SaaS Traffic Flow Architecture

## Overview

This document describes the complete traffic flow architecture for a scalable, cell-based multi-tenant SaaS platform supporting millions of tenants across thousands of microservices.

## Architecture Layers

```
Internet/Clients
       ↓
[Cloud Load Balancer]
       ↓
[Nginx Ingress Controller] (Tenant Resolution)
       ↓
[Service Mesh] (Linkerd/Istio)
       ↓
[Application Services] (Go Microservices)
       ↓
[Data Layer] (MongoDB, Redis, etc.)
```

## Detailed Traffic Flow

### Layer 1: Cloud Load Balancer (AWS ALB / GCP Load Balancer)

**Purpose:** Distribute traffic across multiple Kubernetes clusters (cells)

**Responsibilities:**
- SSL/TLS termination
- DDoS protection
- Geographic routing
- Health checks
- Connection pooling

**Configuration:**
```yaml
# AWS ALB Example
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller
  namespace: core-system
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:..."
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 443
    protocol: TCP
    name: https
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: nginx-ingress-controller
```

**Traffic Flow:**
```
Client Request → Cloud LB (SSL Termination) → Nginx Ingress (NodePort/LoadBalancer)
```

### Layer 2: Nginx Ingress Controller (Tenant Resolution)

**Purpose:** Route traffic based on tenant identification patterns

**Namespace:** `core-system`

**Components:**
- Nginx Ingress Controller Deployment
- Tenant Mapper Service (for custom domain resolution)
- Rate Limiting and WAF rules

#### Pattern A: Subfolder-Based Routing

**Request Flow:**
```
1. Client: GET https://saas.yourdomain.com/tenant-123/api/users/profile
2. Cloud LB: Forward to Nginx Ingress
3. Nginx Ingress:
   a. Match regex: /([^/]+)/api/(.*)
   b. Extract tenant_id = "tenant-123"
   c. Set X-Tenant-ID: tenant-123
   d. Rewrite URI: /api/users/profile
   e. Forward to Service Mesh
4. Service Mesh: Route to tenant-workloads/user-service
5. User Service: Read X-Tenant-ID header, query with tenant isolation
```

**Nginx Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-tenant-subfolder
  namespace: core-system
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      set $tenant_id '';
      if ($request_uri ~* "^/([^/]+)/api/(.*)$") {
        set $tenant_id $1;
      }
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header X-Tenant-ID $tenant_id;
    nginx.ingress.kubernetes.io/rewrite-target: /api/$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: saas.yourdomain.com
    http:
      paths:
      - path: /([^/]+)/api/(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

#### Pattern B: Custom Domain Routing

**Request Flow:**
```
1. Client: GET https://customer1.com/api/users/profile
2. Cloud LB: Forward to Nginx Ingress
3. Nginx Ingress:
   a. Trigger auth-url subrequest
   b. Call: http://tenant-mapper.shared-services.svc.cluster.local
   c. Headers: X-Original-Host: customer1.com
4. Tenant Mapper Service:
   a. Read X-Original-Host header
   b. Query Redis: GET domain:customer1.com
   c. Result: tenant-456
   d. Return 200 OK with X-Tenant-ID: tenant-456
5. Nginx Ingress:
   a. Copy X-Tenant-ID from auth response
   b. Forward to Service Mesh with header
6. Service Mesh: Route to tenant-workloads/user-service
7. User Service: Read X-Tenant-ID header, query with tenant isolation
```

**Nginx Configuration:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-tenant-custom-domain
  namespace: core-system
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "http://tenant-mapper.shared-services.svc.cluster.local"
    nginx.ingress.kubernetes.io/auth-method: "GET"
    nginx.ingress.kubernetes.io/auth-response-headers: "X-Tenant-ID"
    nginx.ingress.kubernetes.io/auth-snippet: |
      proxy_set_header X-Original-Host $host;
      proxy_set_header X-Forwarded-Host $host;
spec:
  ingressClassName: nginx
  rules:
  - host: "*.yourdomain.com"
    http:
      paths:
      - path: /api/(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-gateway
            port:
              number: 8080
```

### Layer 3: Service Mesh (Linkerd/Istio)

**Purpose:** Secure service-to-service communication with mTLS, observability, and traffic management

**Namespace:** Deployed across all namespaces

**Key Features:**
- Mutual TLS (mTLS) between services
- Distributed tracing
- Circuit breaking
- Retry policies
- Traffic splitting (canary deployments)
- Service-level metrics

#### Linkerd Configuration

**Installation:**
```bash
# Install Linkerd CLI
curl -sL https://run.linkerd.io/install | sh

# Install Linkerd control plane in core-system
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# Verify installation
linkerd check
```

**Mesh Injection:**
```yaml
# Automatically inject Linkerd proxy into tenant-workloads namespace
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-workloads
  annotations:
    linkerd.io/inject: enabled
```

**Service Profile for Retry and Timeout:**
```yaml
apiVersion: linkerd.io/v1alpha2
kind: ServiceProfile
metadata:
  name: user-service.tenant-workloads.svc.cluster.local
  namespace: tenant-workloads
spec:
  routes:
  - name: GET /api/users/{id}
    condition:
      method: GET
      pathRegex: /api/users/[^/]*
    timeout: 5s
    retryBudget:
      retryRatio: 0.2
      minRetriesPerSecond: 10
      ttl: 10s
```

#### Istio Configuration (Alternative)

**Installation:**
```bash
# Install Istio
istioctl install --set profile=production

# Enable sidecar injection
kubectl label namespace tenant-workloads istio-injection=enabled
```

**Virtual Service for Traffic Splitting:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service
  namespace: tenant-workloads
spec:
  hosts:
  - user-service
  http:
  - match:
    - headers:
        x-tenant-id:
          prefix: "premium-"
    route:
    - destination:
        host: user-service
        subset: v2
      weight: 100
  - route:
    - destination:
        host: user-service
        subset: v1
      weight: 100
```

**Destination Rule:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: user-service
  namespace: tenant-workloads
spec:
  host: user-service
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

### Layer 4: Application Services (Go Microservices)

**Purpose:** Execute business logic with tenant isolation

**Namespaces:** `tenant-workloads`, `shared-services`

**Service Architecture:**

```
tenant-workloads/
├── user-service (Port 8080)
├── order-service (Port 8081)
├── inventory-service (Port 8082)
├── payment-service (Port 8083)
└── notification-service (Port 8084)

shared-services/
├── api-gateway (Port 8080) [Public Tier]
├── auth-service (Port 8081)
├── media-api (Port 8082)
└── tenant-mapper (Port 80)
```

**Service Communication Flow:**
```
Nginx Ingress (X-Tenant-ID: tenant-123)
    ↓
API Gateway (shared-services)
    ├─→ Auth Service (validate token)
    ├─→ User Service (tenant-workloads) [X-Tenant-ID: tenant-123]
    ├─→ Order Service (tenant-workloads) [X-Tenant-ID: tenant-123]
    └─→ Media API (shared-services)
```

**Go Service Example:**
```go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/vhvplatform/go-infrastructure/server/middleware"
)

func main() {
    r := gin.Default()
    
    // Apply tenancy middleware to all API routes
    api := r.Group("/api")
    api.Use(middleware.TenancyMiddleware())
    {
        api.GET("/users/:id", GetUserHandler)
        api.POST("/users", CreateUserHandler)
    }
    
    r.Run(":8080")
}

func GetUserHandler(c *gin.Context) {
    tenantID := middleware.MustGetTenantID(c)
    userID := c.Param("id")
    
    // Query with tenant isolation
    user, err := db.Users.FindOne(ctx, bson.M{
        "tenant_id": tenantID,
        "_id":       userID,
    })
    
    if err != nil {
        c.JSON(404, gin.H{"error": "User not found"})
        return
    }
    
    c.JSON(200, user)
}
```

### Layer 5: Data Layer

**Purpose:** Persist and retrieve tenant-isolated data

**Components:**
- MongoDB (tenant-isolated collections)
- Redis (domain mappings, sessions, cache)
- PostgreSQL (if needed)

**Data Isolation Strategy:**

**Option 1: Shared Database with Tenant ID (Recommended for scale)**
```javascript
// MongoDB Example
db.users.createIndex({ tenant_id: 1, _id: 1 })
db.users.find({ tenant_id: "tenant-123", email: "user@example.com" })

// Every query MUST include tenant_id
```

**Option 2: Database per Tenant (For premium/isolated tenants)**
```javascript
// Separate database for each premium tenant
db_tenant_456.users.find({ email: "user@example.com" })
```

## Complete Request Flow Example

### Scenario: User fetches their profile via custom domain

**Request:**
```http
GET /api/users/profile HTTP/1.1
Host: acmecorp.com
Authorization: Bearer eyJhbGc...
```

**Step-by-Step Flow:**

1. **DNS Resolution**
   - Client resolves `acmecorp.com` → Cloud LB IP
   
2. **Cloud Load Balancer**
   - Receives HTTPS request
   - Terminates SSL
   - Routes to Nginx Ingress Controller in `core-system` namespace
   
3. **Nginx Ingress - Auth Subrequest**
   - Matches host `acmecorp.com`
   - Triggers auth-url: `http://tenant-mapper.shared-services.svc.cluster.local`
   - Sends headers: `X-Original-Host: acmecorp.com`
   
4. **Tenant Mapper Service**
   - Receives subrequest
   - Queries Redis: `GET domain:acmecorp.com`
   - Result: `tenant-abc123`
   - Returns: `200 OK` with `X-Tenant-ID: tenant-abc123`
   
5. **Nginx Ingress - Forward Request**
   - Copies `X-Tenant-ID: tenant-abc123` header
   - Forwards to: `api-gateway.shared-services.svc.cluster.local:8080`
   - Path: `/api/users/profile`
   
6. **Service Mesh (Linkerd/Istio)**
   - Intercepts request at API Gateway
   - Applies mTLS
   - Traces request with tenant ID
   - Forwards to API Gateway pod
   
7. **API Gateway Service**
   - Receives request with `X-Tenant-ID: tenant-abc123`
   - Validates JWT token
   - Routes to User Service: `user-service.tenant-workloads.svc.cluster.local:8080`
   - Forwards `X-Tenant-ID` header
   
8. **Service Mesh - Internal Call**
   - Intercepts API Gateway → User Service call
   - Applies mTLS
   - Adds distributed tracing headers
   - Circuit breaker policy
   
9. **User Service**
   - Tenancy middleware extracts `X-Tenant-ID: tenant-abc123`
   - Validates tenant ID format
   - Stores in request context
   - Handler executes: `GetUserProfile(ctx, tenantID, userID)`
   
10. **Database Query**
    ```javascript
    db.users.findOne({
      tenant_id: "tenant-abc123",
      _id: ObjectId("...")
    })
    ```
    
11. **Response Flow** (reverse path)
    - User Service → Service Mesh → API Gateway
    - API Gateway → Service Mesh → Nginx Ingress
    - Nginx Ingress → Cloud LB → Client
    
12. **Observability**
    - Distributed trace spans collected
    - Metrics: request duration, status code
    - Logs: tenant ID, user ID, action
    - All tagged with `tenant_id: tenant-abc123`

## Network Policies

**3rd Party Sandbox Isolation:**
```yaml
# Only allow sandbox to call public API gateway
# Block all internal services and databases
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-public-api-only
  namespace: 3rd-party-sandbox
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: shared-services
      podSelector:
        matchLabels:
          app: api-gateway
          tier: public
    ports:
    - protocol: TCP
      port: 8080
```

## Scaling Considerations

### Cell-Based Architecture

**Deployment Model:**
```
Region: us-east-1
├── Cell-1 (Cluster A): Tenants 1-10,000
├── Cell-2 (Cluster B): Tenants 10,001-20,000
├── Cell-3 (Cluster C): Tenants 20,001-30,000
└── Cell-N (Cluster N): Tenants ...
```

**DNS-Based Routing:**
- Use GeoDNS for regional routing
- Cell-level health checks
- Gradual traffic shifting during failures

### Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
  namespace: tenant-workloads
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 10
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Security Best Practices

1. **mTLS Everywhere:** All service-to-service communication encrypted
2. **Network Policies:** Zero-trust model with explicit allow rules
3. **Tenant Isolation:** Always validate and use tenant ID in queries
4. **Rate Limiting:** Per-tenant rate limits at Nginx Ingress
5. **Secrets Management:** Use Sealed Secrets or External Secrets Operator
6. **Pod Security:** Enforce restricted PSS in all namespaces
7. **RBAC:** Least privilege access for service accounts

## Monitoring and Observability

**Metrics Collection:**
- Prometheus scrapes all services
- Custom metrics: `http_requests_total{tenant_id="..."}`
- Alert on per-tenant anomalies

**Distributed Tracing:**
- Jaeger/Tempo integration with Service Mesh
- Trace tenant flow across services
- Identify bottlenecks per tenant

**Logging:**
- Structured JSON logs with tenant_id
- Centralized with Loki/ELK
- Query by tenant for debugging

## Conclusion

This architecture provides:
- ✅ Horizontal scalability to millions of tenants
- ✅ Secure tenant isolation with network policies
- ✅ Flexible routing (subfolder + custom domain)
- ✅ Observability across all layers
- ✅ Service mesh for resilient communication
- ✅ Cell-based architecture for blast radius control

The layered approach ensures each component focuses on its core responsibility while maintaining end-to-end tenant isolation.
