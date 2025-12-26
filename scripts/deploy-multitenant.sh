#!/bin/bash
# deploy-multitenant.sh - Deploy Hybrid Multi-tenant SaaS Infrastructure
# Triển khai Hạ tầng SaaS Đa-thuê bao Lai

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-dev}"
METHOD="${2:-kustomize}"
NAMESPACE="saas-framework"

if [ "$ENVIRONMENT" == "prod" ]; then
    NAMESPACE="saas-framework-prod"
elif [ "$ENVIRONMENT" == "staging" ]; then
    NAMESPACE="saas-framework-staging"
fi

echo "============================================"
echo "Deploying Hybrid Multi-tenant SaaS"
echo "Triển khai SaaS Đa-thuê bao Lai"
echo "============================================"
echo ""
echo -e "Environment / Môi trường: ${BLUE}$ENVIRONMENT${NC}"
echo -e "Method / Phương pháp: ${BLUE}$METHOD${NC}"
echo -e "Namespace: ${BLUE}$NAMESPACE${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
echo -e "${YELLOW}Kiểm tra yêu cầu...${NC}"
echo ""

MISSING_TOOLS=()

if ! command_exists kubectl; then
    MISSING_TOOLS+=("kubectl")
fi

if [ "$METHOD" == "helm" ] && ! command_exists helm; then
    MISSING_TOOLS+=("helm")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required tools: ${MISSING_TOOLS[*]}${NC}"
    echo -e "${RED}Lỗi: Thiếu công cụ: ${MISSING_TOOLS[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Check cluster connection
echo -e "${YELLOW}Checking Kubernetes cluster connection...${NC}"
echo -e "${YELLOW}Kiểm tra kết nối Kubernetes cluster...${NC}"
if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected to cluster${NC}"
    kubectl cluster-info | head -1
else
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster${NC}"
    echo -e "${RED}✗ Không thể kết nối đến Kubernetes cluster${NC}"
    exit 1
fi
echo ""

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating namespace if not exists...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace ready: $NAMESPACE${NC}"
echo ""

# Create secrets if they don't exist
echo -e "${YELLOW}Checking secrets...${NC}"
if ! kubectl get secret saas-secrets -n $NAMESPACE >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating secrets...${NC}"
    
    if [ "$ENVIRONMENT" == "prod" ]; then
        echo -e "${RED}IMPORTANT: You should create production secrets manually with secure values!${NC}"
        echo -e "${RED}QUAN TRỌNG: Bạn nên tạo secrets production thủ công với giá trị bảo mật!${NC}"
        echo ""
        echo "Example / Ví dụ:"
        echo "  kubectl create secret generic saas-secrets \\"
        echo "    --namespace=$NAMESPACE \\"
        echo "    --from-literal=mongodb-uri='<secure-value>' \\"
        echo "    --from-literal=redis-password='<secure-value>' \\"
        echo "    --from-literal=jwt-secret='<secure-value>' \\"
        echo "    --from-literal=rabbitmq-password='<secure-value>'"
        echo ""
        read -p "Continue with dev secrets? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    kubectl create secret generic saas-secrets \
        --namespace=$NAMESPACE \
        --from-literal=mongodb-uri="mongodb://localhost:27017/saas" \
        --from-literal=redis-password="dev-redis-password" \
        --from-literal=jwt-secret="dev-jwt-secret-key" \
        --from-literal=rabbitmq-password="dev-rabbitmq-password"
    
    echo -e "${GREEN}✓ Secrets created${NC}"
else
    echo -e "${GREEN}✓ Secrets already exist${NC}"
fi
echo ""

# Deploy based on method
if [ "$METHOD" == "helm" ]; then
    echo -e "${YELLOW}Deploying with Helm...${NC}"
    echo -e "${YELLOW}Triển khai với Helm...${NC}"
    echo ""
    
    VALUES_FILE="helm/charts/saas-platform/values.$ENVIRONMENT.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
        VALUES_FILE="helm/charts/saas-platform/values.yaml"
    fi
    
    helm upgrade --install saas-platform helm/charts/saas-platform \
        -f "$VALUES_FILE" \
        --namespace $NAMESPACE \
        --create-namespace \
        --wait \
        --timeout 10m
    
    echo -e "${GREEN}✓ Helm deployment completed${NC}"
    
elif [ "$METHOD" == "kustomize" ]; then
    echo -e "${YELLOW}Deploying with Kustomize...${NC}"
    echo -e "${YELLOW}Triển khai với Kustomize...${NC}"
    echo ""
    
    OVERLAY_PATH="kubernetes/overlays/$ENVIRONMENT"
    if [ ! -d "$OVERLAY_PATH" ]; then
        OVERLAY_PATH="kubernetes/base"
    fi
    
    kubectl apply -k "$OVERLAY_PATH"
    
    echo -e "${GREEN}✓ Kustomize deployment completed${NC}"
    
else
    echo -e "${RED}Unknown method: $METHOD${NC}"
    echo -e "${RED}Use 'helm' or 'kustomize'${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
echo -e "${YELLOW}Đợi deployments sẵn sàng...${NC}"
echo ""

# Wait for critical deployments
CRITICAL_DEPLOYMENTS=("redis" "tenant-mapper")

for deployment in "${CRITICAL_DEPLOYMENTS[@]}"; do
    echo -n "Waiting for $deployment..."
    if kubectl get statefulset $deployment -n $NAMESPACE >/dev/null 2>&1; then
        kubectl rollout status statefulset/$deployment -n $NAMESPACE --timeout=5m
    elif kubectl get deployment $deployment -n $NAMESPACE >/dev/null 2>&1; then
        kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=5m
    else
        echo " not found (may be optional)"
    fi
done

echo ""
echo -e "${GREEN}✓ All critical deployments ready${NC}"
echo ""

# Display status
echo "============================================"
echo "Deployment Status / Trạng thái Triển khai"
echo "============================================"
echo ""

echo "Pods:"
kubectl get pods -n $NAMESPACE

echo ""
echo "Services:"
kubectl get svc -n $NAMESPACE

echo ""
echo "Ingress:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "============================================"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Triển khai thành công!${NC}"
echo "============================================"
echo ""

# Show next steps
echo "Next steps / Các bước tiếp theo:"
echo ""
echo "1. Configure domain mappings in Redis:"
echo "   Cấu hình ánh xạ tên miền trong Redis:"
echo ""
echo "   kubectl port-forward -n $NAMESPACE statefulset/redis 6379:6379 &"
echo "   redis-cli -a <password> SET domain:customer.com tenant-123"
echo ""
echo "2. Test Pattern A (Subfolder):"
echo "   Kiểm tra Mô hình A (Thư mục con):"
echo ""
echo "   ./scripts/test-pattern-a.sh"
echo ""
echo "3. Test Pattern B (Custom Domain):"
echo "   Kiểm tra Mô hình B (Tên miền tùy chỉnh):"
echo ""
echo "   ./scripts/test-pattern-b.sh"
echo ""
echo "4. Monitor logs:"
echo "   Giám sát logs:"
echo ""
echo "   kubectl logs -n $NAMESPACE -l app=tenant-mapper -f"
echo ""
echo "5. Access monitoring:"
echo "   Truy cập giám sát:"
echo ""
echo "   kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000"
echo ""

# Show ingress information
if [ "$ENVIRONMENT" != "prod" ]; then
    echo "For local testing, add to /etc/hosts:"
    echo "Để test local, thêm vào /etc/hosts:"
    echo ""
    if command_exists minikube; then
        INGRESS_IP=$(minikube ip)
    else
        INGRESS_IP="127.0.0.1"
    fi
    echo "  $INGRESS_IP saas.local"
    echo "  $INGRESS_IP customer.local"
    echo "  $INGRESS_IP acme.local"
    echo ""
fi

echo "Documentation / Tài liệu:"
echo "  - English: docs/HYBRID_MULTITENANT_DEPLOYMENT.md"
echo "  - Tiếng Việt: docs/HYBRID_MULTITENANT_DEPLOYMENT_VI.md"
echo ""
