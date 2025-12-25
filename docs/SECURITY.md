# Security Best Practices

This document outlines security best practices for the go-infrastructure project.

## 🔒 Security Principles

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Minimum necessary permissions
3. **Zero Trust**: Verify everything, trust nothing
4. **Encryption Everywhere**: Data at rest and in transit
5. **Audit Everything**: Comprehensive logging and monitoring

## 🛡️ Infrastructure Security

### GKE Cluster Security

#### 1. Workload Identity

**Implementation**:
```yaml
# Enable Workload Identity on cluster (done in Terraform)
workload_identity_config {
  workload_pool = "${var.project_id}.svc.id.goog"
}

# Kubernetes service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  annotations:
    iam.gke.io/gcp-service-account: app-sa@project.iam.gserviceaccount.com
```

**Benefits**:
- No need for service account keys in pods
- Automatic credential rotation
- Fine-grained access control
- Audit trail through Cloud IAM

#### 2. Network Policies

**Example**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-policy
spec:
  podSelector:
    matchLabels:
      app: api-gateway
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: backend-services
    ports:
    - protocol: TCP
      port: 8080
```

#### 3. Pod Security Standards

**Pod Security Policy** (deprecated, use Pod Security Standards):
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Security Context**:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

#### 4. RBAC Configuration

**Example Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### MongoDB Atlas Security

#### 1. Network Access Control

**IP Whitelisting**:
```hcl
# Terraform configuration
variable "mongodb_ip_whitelist" {
  description = "List of IP addresses to whitelist"
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.mongodb_ip_whitelist) > 0
    error_message = "At least one IP must be whitelisted."
  }
}
```

**Best Practices**:
- Never use `0.0.0.0/0` in production
- Use Cloud NAT to provide consistent egress IPs from GKE, then whitelist those NAT IPs (requires additional Terraform configuration not included in current modules)
- Consider VPC peering for private connectivity (more secure than public IPs)
- Use MongoDB Atlas Private Endpoints for direct private connectivity
- Regularly review and update whitelist

#### 2. Database User Permissions

**Minimal Privileges**:
```hcl
resource "mongodbatlas_database_user" "app_user" {
  username           = "app_user"
  password           = var.database_password
  project_id         = var.project_id
  auth_database_name = "admin"
  
  # Only readWrite on specific database
  roles {
    role_name     = "readWrite"
    database_name = var.database_name
  }
}
```

#### 3. Encryption

**At Rest**:
- Enabled by default on MongoDB Atlas
- Uses AES-256 encryption
- Keys managed by cloud provider

**In Transit**:
- TLS 1.2+ required
- Certificate verification enabled
- Connection string must use `mongodb+srv://`

### Secret Management

#### 1. Kubernetes Secrets

**Creation**:
```bash
# Create from literal
kubectl create secret generic db-credentials \
  --from-literal=username=myuser \
  --from-literal=password=mypassword

# Create from file
kubectl create secret generic tls-cert \
  --from-file=tls.crt=./cert.crt \
  --from-file=tls.key=./cert.key
```

**Usage in Pods**:
```yaml
env:
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: password
```

#### 2. External Secrets Operator (Recommended)

**Setup**:
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets
```

**Example**:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcpsm-secret-store
spec:
  provider:
    gcpsm:
      projectID: "my-project"
      auth:
        workloadIdentity:
          clusterLocation: us-central1
          clusterName: my-cluster
          serviceAccountRef:
            name: external-secrets-sa

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcpsm-secret-store
    kind: SecretStore
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: db-password
```

## 🔐 Application Security

### Container Security

#### 1. Base Images

**Best Practices**:
```dockerfile
# Use minimal base images
FROM gcr.io/distroless/static-debian11

# Or use Alpine for smaller size
FROM alpine:3.18

# Avoid using 'latest' tag
FROM node:18.17-alpine

# Run as non-root user
USER 1000:1000
```

#### 2. Image Scanning

**GitHub Actions**:
```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'gcr.io/project/image:tag'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
```

#### 3. Image Signing

**Using Cosign**:
```bash
# Sign image
cosign sign gcr.io/project/image:tag

# Verify signature
cosign verify gcr.io/project/image:tag
```

### Code Security

#### 1. Dependency Scanning

**Go Dependencies**:
```bash
# Check for vulnerabilities
go list -json -m all | nancy sleuth
```

**npm Dependencies**:
```bash
# Audit dependencies
npm audit

# Fix vulnerabilities
npm audit fix
```

#### 2. Static Code Analysis

**SonarQube**:
```yaml
# sonar-project.properties
sonar.projectKey=go-infrastructure
sonar.sources=.
sonar.exclusions=**/test/**,**/vendor/**
sonar.go.coverage.reportPaths=coverage.out
```

#### 3. Secret Scanning

**git-secrets**:
```bash
# Install git-secrets
git secrets --install

# Add patterns
git secrets --add 'password\s*=\s*["\'].*["\']'
git secrets --add '[A-Za-z0-9+/]{40}'

# Scan repository
git secrets --scan
```

## 🔍 Monitoring & Auditing

### Audit Logging

**GKE Audit Logs**:
```bash
# Enable audit logging
gcloud container clusters update CLUSTER_NAME \
  --enable-cloud-logging \
  --logging=SYSTEM,WORKLOAD \
  --enable-cloud-monitoring
```

**Query Logs**:
```bash
# View audit logs
gcloud logging read "resource.type=k8s_cluster" \
  --limit 50 \
  --format json
```

### Security Monitoring

**Prometheus Alerts**:
```yaml
groups:
- name: security_alerts
  rules:
  - alert: UnauthorizedAccessAttempt
    expr: rate(apiserver_audit_event_total{verb="create",code=~"401|403"}[5m]) > 10
    annotations:
      summary: "High rate of unauthorized access attempts"
      
  - alert: PrivilegedPodCreated
    expr: count(kube_pod_container_status_running{container_security_context_privileged="true"}) > 0
    annotations:
      summary: "Privileged pod detected"
```

## 🚨 Incident Response

### Security Incident Checklist

1. **Immediate Response**
   - [ ] Isolate affected systems
   - [ ] Preserve evidence
   - [ ] Notify security team
   - [ ] Document timeline

2. **Investigation**
   - [ ] Review audit logs
   - [ ] Check for data exfiltration
   - [ ] Identify attack vector
   - [ ] Assess impact

3. **Remediation**
   - [ ] Patch vulnerabilities
   - [ ] Rotate compromised credentials
   - [ ] Update firewall rules
   - [ ] Deploy fixes

4. **Post-Incident**
   - [ ] Conduct post-mortem
   - [ ] Update security policies
   - [ ] Improve monitoring
   - [ ] Team training

### Emergency Contacts

```yaml
security_contacts:
  - role: Security Lead
    email: security@company.com
    phone: +1-xxx-xxx-xxxx
    
  - role: Platform Team
    email: platform@company.com
    slack: #platform-team
    
  - role: On-Call
    pagerduty: https://company.pagerduty.com
```

## 📋 Security Checklist

### Pre-Deployment

- [ ] Secrets are not in code
- [ ] Dependencies are up to date
- [ ] Images are scanned
- [ ] RBAC is configured
- [ ] Network policies are in place
- [ ] Pod security contexts are set
- [ ] Workload Identity is enabled
- [ ] Resource limits are defined

### Production

- [ ] TLS everywhere
- [ ] MongoDB IP whitelist is restrictive
- [ ] Audit logging is enabled
- [ ] Monitoring alerts are configured
- [ ] Backup and recovery tested
- [ ] Incident response plan documented
- [ ] Security reviews scheduled
- [ ] Vulnerability scanning automated

### Monthly Reviews

- [ ] Review IAM permissions
- [ ] Audit service accounts
- [ ] Check for unused resources
- [ ] Review firewall rules
- [ ] Update dependencies
- [ ] Review audit logs
- [ ] Test disaster recovery
- [ ] Security training

## 📚 Additional Resources

- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [MongoDB Security Checklist](https://www.mongodb.com/docs/manual/administration/security-checklist/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

## 🆘 Reporting Security Issues

**DO NOT** create public GitHub issues for security vulnerabilities.

Instead:
1. Email security@company.com
2. Use GPG key: [link to public key]
3. Include detailed description
4. Provide reproduction steps
5. Expected 24-48 hour response time

## 📝 Compliance

This infrastructure aims to comply with:
- SOC 2 Type II
- GDPR
- HIPAA (if applicable)
- PCI DSS (if applicable)

Regular audits are conducted to ensure ongoing compliance.
