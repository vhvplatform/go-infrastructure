# Kiến trúc SaaS Đa-thuê bao Lai (Hybrid) - Hướng dẫn Triển khai

## Mục lục
- [Tổng quan](#tổng-quan)
- [Kiến trúc](#kiến-trúc)
- [Yêu cầu](#yêu-cầu)
- [Triển khai môi trường Development](#triển-khai-môi-trường-development)
- [Triển khai môi trường Production](#triển-khai-môi-trường-production)
- [Cấu hình](#cấu-hình)
- [Kiểm thử](#kiểm-thử)
- [Xử lý sự cố](#xử-lý-sự-cố)

## Tổng quan

Hướng dẫn này cung cấp chi tiết về cách triển khai hạ tầng SaaS đa-thuê bao lai hỗ trợ hai mô hình định tuyến:

1. **Mô hình A (Thư mục con)**: `saas.com/{tenant_id}/api/{service_name}/*`
2. **Mô hình B (Tên miền tùy chỉnh)**: `customer.com/api/{service_name}/*`

### Các thành phần chính

- **Nginx Ingress Controller**: Định tuyến lưu lượng dựa trên mô hình
- **Tenant Mapper Service**: Phân giải tên miền thành tenant ID
- **Redis StatefulSet**: Lưu trữ ánh xạ tên miền và dữ liệu session
- **Microservices**: Các dịch vụ backend (auth, user, tenant, v.v.)

## Kiến trúc

Xem các sơ đồ kiến trúc:
- [Tổng quan Kiến trúc](diagrams/architecture-overview.puml)
- [Luồng dữ liệu - Mô hình A](diagrams/traffic-flow-pattern-a.puml)
- [Luồng dữ liệu - Mô hình B](diagrams/traffic-flow-pattern-b.puml)

![Tổng quan Kiến trúc](diagrams/output/architecture-overview.png)

### Luồng định tuyến lưu lượng

#### Mô hình A: Định tuyến theo Thư mục con
```
Yêu cầu: https://saas.com/tenant-123/api/users/profile
         ↓
    Nginx Ingress
         ↓
    Trích xuất tenant_id = "tenant-123"
         ↓
    Chèn header X-Tenant-ID: tenant-123
         ↓
    Viết lại URI: /api/users/profile
         ↓
    Định tuyến đến: user-service
         ↓
    Backend nhận được:
    - X-Tenant-ID: tenant-123
    - URI: /api/users/profile
```

#### Mô hình B: Định tuyến theo Tên miền Tùy chỉnh
```
Yêu cầu: https://customer.com/api/users/profile
         ↓
    Nginx Ingress
         ↓
    Gọi auth-url: http://tenant-mapper
         ↓
    Tenant Mapper:
    - Đọc X-Original-Host: customer.com
    - Truy vấn Redis: domain:customer.com → tenant-456
    - Trả về X-Tenant-ID: tenant-456
         ↓
    Nginx chèn X-Tenant-ID: tenant-456
         ↓
    Định tuyến đến: user-service
         ↓
    Backend nhận được:
    - X-Tenant-ID: tenant-456
    - URI: /api/users/profile
```

## Yêu cầu

### Công cụ cần thiết

| Công cụ | Phiên bản | Cài đặt |
|---------|-----------|---------|
| `kubectl` | v1.27+ | [Cài đặt](https://kubernetes.io/docs/tasks/tools/) |
| `helm` | v3.12+ | [Cài đặt](https://helm.sh/docs/intro/install/) |
| `kustomize` | v5.0+ | [Cài đặt](https://kubectl.docs.kubernetes.io/installation/kustomize/) |
| `docker` | v24+ | [Cài đặt](https://docs.docker.com/get-docker/) |
| `redis-cli` | Mới nhất | `apt-get install redis-tools` |

### Yêu cầu về Hạ tầng

**Development:**
- Kubernetes cluster (minikube, kind, hoặc GKE)
- Tối thiểu 4 CPU cores, 8GB RAM
- 50GB dung lượng lưu trữ

**Production:**
- GKE cluster (3+ nodes)
- n1-standard-4 trở lên
- 100GB+ SSD storage
- Hỗ trợ Load balancer

### Yêu cầu về Quyền truy cập

- Truy cập Kubernetes cluster (đã cấu hình kubeconfig)
- Truy cập Container registry (GCR hoặc Docker Hub)
- Quyền quản lý DNS (cho tên miền tùy chỉnh)
- Chứng chỉ TLS (Let's Encrypt hoặc tùy chỉnh)

## Triển khai môi trường Development

### Bước 1: Clone Repository

```bash
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure
```

### Bước 2: Thiết lập Kubernetes Cluster Local

#### Sử dụng Minikube

```bash
# Khởi động minikube với tài nguyên đủ
minikube start --cpus=4 --memory=8192 --disk-size=50g

# Bật các addon cần thiết
minikube addons enable ingress
minikube addons enable storage-provisioner

# Kiểm tra cluster
kubectl cluster-info
```

#### Sử dụng kind

```bash
# Tạo cluster với hỗ trợ ingress
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

# Cài đặt Nginx Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Đợi ingress controller sẵn sàng
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### Bước 3: Tạo Namespace và Secrets

```bash
# Tạo namespace
kubectl create namespace saas-framework

# Tạo secrets
kubectl create secret generic saas-secrets \
  --namespace=saas-framework \
  --from-literal=mongodb-uri="mongodb://localhost:27017/saas" \
  --from-literal=redis-password="dev-redis-password" \
  --from-literal=jwt-secret="dev-jwt-secret-key" \
  --from-literal=rabbitmq-password="dev-rabbitmq-password"
```

### Bước 4: Build Tenant Mapper Service

```bash
# Di chuyển đến thư mục tenant-mapper
cd services/tenant-mapper

# Build Docker image
docker build -t tenant-mapper:dev .

# Load image vào minikube (nếu dùng minikube)
minikube image load tenant-mapper:dev

# Hoặc push lên registry
# docker tag tenant-mapper:dev gcr.io/your-project/tenant-mapper:dev
# docker push gcr.io/your-project/tenant-mapper:dev
```

### Bước 5: Triển khai Infrastructure với Kustomize

```bash
# Triển khai base infrastructure
kubectl apply -k kubernetes/base/

# Kiểm tra deployments
kubectl get pods -n saas-framework

# Kết quả mong đợi:
# NAME                              READY   STATUS    RESTARTS   AGE
# redis-0                           1/1     Running   0          2m
# tenant-mapper-xxx                 1/1     Running   0          2m
# auth-service-xxx                  1/1     Running   0          2m
# user-service-xxx                  1/1     Running   0          2m
# ...
```

### Bước 6: Cấu hình Redis với Ánh xạ Tên miền

```bash
# Port-forward Redis
kubectl port-forward -n saas-framework statefulset/redis 6379:6379 &

# Đặt mật khẩu Redis
export REDIS_PASSWORD="dev-redis-password"

# Thêm ánh xạ tên miền
redis-cli -a $REDIS_PASSWORD SET domain:customer.local tenant-123
redis-cli -a $REDIS_PASSWORD SET domain:acme.local tenant-456
redis-cli -a $REDIS_PASSWORD SET domain:demo.local tenant-789

# Kiểm tra ánh xạ
redis-cli -a $REDIS_PASSWORD KEYS "domain:*"
```

### Bước 7: Cập nhật /etc/hosts để Test Local

```bash
# Thêm các entry vào /etc/hosts
sudo bash -c 'cat >> /etc/hosts <<EOF
127.0.0.1 saas.local
127.0.0.1 customer.local
127.0.0.1 acme.local
127.0.0.1 demo.local
EOF'
```

### Bước 8: Kiểm tra Các Mô hình Định tuyến

#### Kiểm tra Mô hình A (Thư mục con)

```bash
# Lấy IP của ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Kiểm tra với tenant_id trong path
curl -H "Host: saas.local" http://$INGRESS_IP/tenant-123/api/health

# Kết quả mong đợi: Nhận response với header X-Tenant-ID
```

#### Kiểm tra Mô hình B (Tên miền Tùy chỉnh)

```bash
# Kiểm tra tên miền tùy chỉnh
curl -H "Host: customer.local" http://$INGRESS_IP/api/health

# Kiểm tra logs của tenant-mapper
kubectl logs -n saas-framework -l app=tenant-mapper --tail=50

# Log mong đợi: "Resolved domain customer.local to tenant: tenant-123"
```

### Bước 9: Triển khai bằng Helm (Phương án thay thế)

```bash
# Cài đặt với Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.dev.yaml \
  --namespace saas-framework \
  --create-namespace

# Kiểm tra trạng thái
helm status saas-platform -n saas-framework

# Liệt kê releases
helm list -n saas-framework
```

## Triển khai môi trường Production

### Bước 1: Chuẩn bị GKE Cluster

```bash
# Đặt project và region
export PROJECT_ID="your-gcp-project"
export REGION="us-central1"
export CLUSTER_NAME="saas-platform-prod"

# Tạo GKE cluster
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

# Lấy credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# Kiểm tra kết nối
kubectl cluster-info
```

### Bước 2: Cài đặt Nginx Ingress Controller

```bash
# Thêm Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Cài đặt Nginx Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"=true \
  --set controller.podAnnotations."prometheus\.io/port"=10254

# Đợi external IP
kubectl get service -n ingress-nginx ingress-nginx-controller --watch
```

### Bước 3: Cài đặt cert-manager cho TLS

```bash
# Cài đặt cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Đợi cert-manager sẵn sàng
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=90s

# Tạo ClusterIssuer cho Let's Encrypt
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

### Bước 4: Tạo Production Secrets

```bash
# Tạo namespace
kubectl create namespace saas-framework-prod

# Tạo mật khẩu bảo mật
export REDIS_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 64)
export RABBITMQ_PASSWORD=$(openssl rand -base64 32)
export MONGODB_URI="mongodb+srv://user:password@cluster.mongodb.net/saas?retryWrites=true&w=majority"

# Tạo secrets
kubectl create secret generic saas-secrets \
  --namespace=saas-framework-prod \
  --from-literal=mongodb-uri="$MONGODB_URI" \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --from-literal=jwt-secret="$JWT_SECRET" \
  --from-literal=rabbitmq-password="$RABBITMQ_PASSWORD"

# Lưu mật khẩu một cách an toàn (dùng secret manager trong production)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env.prod.backup
echo "JWT_SECRET=$JWT_SECRET" >> .env.prod.backup
echo "RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD" >> .env.prod.backup
```

### Bước 5: Build và Push Container Images

```bash
# Build tenant-mapper
cd services/tenant-mapper
docker build -t gcr.io/$PROJECT_ID/tenant-mapper:1.0.0 .
docker push gcr.io/$PROJECT_ID/tenant-mapper:1.0.0

# Tag là latest
docker tag gcr.io/$PROJECT_ID/tenant-mapper:1.0.0 gcr.io/$PROJECT_ID/tenant-mapper:latest
docker push gcr.io/$PROJECT_ID/tenant-mapper:latest

cd ../..
```

### Bước 6: Cập nhật Production Manifests

```bash
# Cập nhật tham chiếu image trong overlays/prod
mkdir -p kubernetes/overlays/prod
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

### Bước 7: Triển khai lên Production

```bash
# Phương án 1: Dùng Kustomize
kubectl apply -k kubernetes/overlays/prod/

# Phương án 2: Dùng Helm
helm upgrade --install saas-platform helm/charts/saas-platform \
  -f helm/charts/saas-platform/values.prod.yaml \
  --namespace saas-framework-prod \
  --create-namespace \
  --wait \
  --timeout 10m

# Kiểm tra deployment
kubectl get pods -n saas-framework-prod
kubectl get ingress -n saas-framework-prod
```

### Bước 8: Cấu hình DNS

```bash
# Lấy IP external của ingress
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Cấu hình bản ghi DNS:"
echo "A    saas.yourdomain.com    $EXTERNAL_IP"
echo "A    *.yourdomain.com       $EXTERNAL_IP"
echo ""
echo "Hoặc dùng wildcard:"
echo "A    *.yourdomain.com       $EXTERNAL_IP"
```

### Bước 9: Load Ánh xạ Tên miền vào Redis

```bash
# Port-forward Redis (production)
kubectl port-forward -n saas-framework-prod statefulset/redis 6379:6379 &

# Đặt mật khẩu Redis
export REDIS_PASSWORD="<your-prod-redis-password>"

# Load ánh xạ tên miền production
redis-cli -a $REDIS_PASSWORD <<EOF
SET domain:customer1.com tenant-a1b2c3
SET domain:customer2.com tenant-d4e5f6
SET domain:acmecorp.com tenant-g7h8i9
EOF

# Kiểm tra
redis-cli -a $REDIS_PASSWORD KEYS "domain:*"
```

### Bước 10: Xác minh Production Deployment

```bash
# Kiểm tra tất cả pods đang chạy
kubectl get pods -n saas-framework-prod

# Kiểm tra ingress
kubectl get ingress -n saas-framework-prod

# Kiểm tra Mô hình A
curl https://saas.yourdomain.com/tenant-a1b2c3/api/health

# Kiểm tra Mô hình B
curl https://customer1.com/api/health

# Kiểm tra logs
kubectl logs -n saas-framework-prod -l app=tenant-mapper --tail=100
```

## Cấu hình

### Biến Môi trường

#### Tenant Mapper Service

| Biến | Mô tả | Mặc định | Bắt buộc |
|------|-------|----------|----------|
| `REDIS_ADDR` | Địa chỉ Redis server | `redis:6379` | Có |
| `REDIS_PASSWORD` | Mật khẩu Redis | - | Có |

#### Backend Services

Tất cả backend services cần đọc header `X-Tenant-ID`:

```go
// Ví dụ trong Go
tenantID := r.Header.Get("X-Tenant-ID")
if tenantID == "" {
    http.Error(w, "Tenant ID required", http.StatusBadRequest)
    return
}
```

### Định dạng Key Redis

Ánh xạ tên miền được lưu trong Redis với định dạng:

```
Key: domain:{hostname}
Value: {tenant_id}

Ví dụ:
domain:customer1.com → tenant-abc123
domain:acmecorp.com → tenant-xyz789
```

### Cấu hình Ingress

#### Cấu hình Mô hình A

Chỉnh sửa `kubernetes/base/ingress/ingress-pattern-a-subfolder.yaml`:

```yaml
spec:
  rules:
  - host: saas.yourdomain.com  # Thay bằng tên miền của bạn
```

#### Cấu hình Mô hình B

Chỉnh sửa `kubernetes/base/ingress/ingress-pattern-b-custom-domain.yaml`:

```yaml
spec:
  rules:
  - host: "*.yourdomain.com"  # Thay bằng wildcard domain của bạn
```

## Kiểm thử

### Unit Testing

```bash
# Test tenant-mapper locally
cd services/tenant-mapper
go test -v ./...
```

### Integration Testing

```bash
# Test toàn bộ workflow
./scripts/test-routing.sh dev

# Test mô hình cụ thể
./scripts/test-pattern-a.sh
./scripts/test-pattern-b.sh
```

### Load Testing

```bash
# Cài đặt hey (HTTP load generator)
go install github.com/rakyll/hey@latest

# Test Mô hình A
hey -n 1000 -c 10 -H "Host: saas.local" \
  http://$INGRESS_IP/tenant-123/api/health

# Test Mô hình B
hey -n 1000 -c 10 -H "Host: customer.local" \
  http://$INGRESS_IP/api/health
```

## Xử lý sự cố

### Các vấn đề thường gặp

#### 1. Tenant Mapper trả về 401

**Vấn đề**: Yêu cầu tên miền tùy chỉnh trả về 401 Unauthorized.

**Giải pháp**:
```bash
# Kiểm tra tên miền có trong Redis không
kubectl port-forward -n saas-framework statefulset/redis 6379:6379
redis-cli -a $REDIS_PASSWORD GET domain:customer.com

# Nếu không tìm thấy, thêm vào
redis-cli -a $REDIS_PASSWORD SET domain:customer.com tenant-123
```

#### 2. Mô hình A không trích xuất Tenant ID

**Vấn đề**: Backend services không nhận header X-Tenant-ID.

**Giải pháp**:
```bash
# Kiểm tra ingress annotations
kubectl get ingress -n saas-framework saas-multi-tenant-subfolder -o yaml

# Xác minh cấu hình nginx
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep tenant
```

#### 3. Kết nối Redis thất bại

**Vấn đề**: Tenant mapper không thể kết nối Redis.

**Giải pháp**:
```bash
# Kiểm tra Redis đang chạy
kubectl get pods -n saas-framework -l app=redis

# Kiểm tra Redis service
kubectl get svc -n saas-framework redis

# Test kết nối Redis
kubectl run redis-test --rm -it --image=redis:7-alpine -- redis-cli -h redis.saas-framework.svc.cluster.local -a $REDIS_PASSWORD ping
```

#### 4. DNS không phân giải

**Vấn đề**: Tên miền tùy chỉnh không phân giải được.

**Giải pháp**:
```bash
# Xác minh bản ghi DNS
nslookup customer.com
dig customer.com

# Kiểm tra IP external của ingress
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Cập nhật DNS để trỏ đến external IP
```

### Lệnh Debug

```bash
# Xem logs tenant-mapper
kubectl logs -n saas-framework -l app=tenant-mapper -f

# Kiểm tra events ingress
kubectl get events -n saas-framework --sort-by='.lastTimestamp'

# Mô tả ingress
kubectl describe ingress -n saas-framework

# Kiểm tra logs nginx ingress controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f

# Test từ trong cluster
kubectl run curl-test --rm -it --image=curlimages/curl -- sh
# curl http://tenant-mapper.saas-framework.svc.cluster.local -H "X-Original-Host: customer.com"
```

### Giám sát

```bash
# Port-forward Prometheus
kubectl port-forward -n saas-framework svc/prometheus 9090:9090

# Port-forward Grafana
kubectl port-forward -n saas-framework svc/grafana 3000:3000

# Xem metrics
open http://localhost:9090  # Prometheus
open http://localhost:3000  # Grafana
```

## Các bước tiếp theo

1. Thiết lập giám sát và cảnh báo
2. Cấu hình chiến lược backup cho Redis
3. Triển khai rate limiting theo từng tenant
4. Thêm custom metrics cho việc sử dụng của tenant
5. Thiết lập tổng hợp log với Loki
6. Cấu hình horizontal pod autoscaling

## Tài nguyên bổ sung

- [Nginx Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Thực hành tốt về Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)

## Hỗ trợ

Đối với các vấn đề hoặc câu hỏi:
- Tạo issue trong repository
- Liên hệ: team@saas-framework.io
- Slack: #go-infrastructure
