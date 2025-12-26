#!/bin/bash
# test-pattern-b.sh - Test Pattern B (Custom domain routing)
# Kiểm tra Mô hình B (Định tuyến tên miền tùy chỉnh)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "Testing Pattern B: Custom Domain Routing"
echo "Kiểm tra Mô hình B: Định tuyến Tên miền Tùy chỉnh"
echo "============================================"
echo ""

# Get ingress IP
if command -v minikube &> /dev/null; then
    INGRESS_IP=$(minikube ip)
    echo -e "${YELLOW}Using Minikube IP: $INGRESS_IP${NC}"
else
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$INGRESS_IP" ]; then
        INGRESS_IP="localhost"
    fi
    echo -e "${YELLOW}Using Ingress IP: $INGRESS_IP${NC}"
fi

# Get Redis password
NAMESPACE="${NAMESPACE:-saas-framework}"
REDIS_PASSWORD=$(kubectl get secret -n $NAMESPACE saas-secrets -o jsonpath='{.data.redis-password}' | base64 -d 2>/dev/null || echo "dev-redis-password")

echo -e "${BLUE}Setting up test data in Redis...${NC}"
echo -e "${BLUE}Thiết lập dữ liệu test trong Redis...${NC}"
echo ""

# Port-forward Redis in background
kubectl port-forward -n $NAMESPACE statefulset/redis 6379:6379 >/dev/null 2>&1 &
PF_PID=$!
sleep 2

# Add test domain mappings
redis-cli -a "$REDIS_PASSWORD" --no-auth-warning SET domain:customer.local tenant-123 >/dev/null 2>&1
redis-cli -a "$REDIS_PASSWORD" --no-auth-warning SET domain:acme.local tenant-456 >/dev/null 2>&1
redis-cli -a "$REDIS_PASSWORD" --no-auth-warning SET domain:demo.local tenant-789 >/dev/null 2>&1

echo -e "${GREEN}✓ Test domains added to Redis${NC}"
echo ""

# Test cases
TEST_CASES=(
    "tenant-123:customer.local:/api/health"
    "tenant-456:acme.local:/api/users"
    "tenant-789:demo.local:/api/tenants"
)

echo "Running tests / Chạy kiểm tra..."
echo ""

PASSED=0
FAILED=0

for test in "${TEST_CASES[@]}"; do
    IFS=':' read -r EXPECTED_TENANT HOST PATH <<< "$test"
    
    echo "Test: $HOST$PATH"
    echo "Expected Tenant ID / Tenant ID mong đợi: $EXPECTED_TENANT"
    
    # Make request with curl and capture response headers
    RESPONSE=$(curl -s -i -H "Host: $HOST" "http://$INGRESS_IP$PATH" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP/" | awk '{print $2}' | head -1)
    
    # Check if request succeeded
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "404" ]; then
        echo -e "${GREEN}✓ Request successful (HTTP $HTTP_CODE)${NC}"
        
        # Check for X-Tenant-ID header in logs
        echo -e "${BLUE}Checking tenant-mapper logs...${NC}"
        TENANT_LOGS=$(kubectl logs -n $NAMESPACE -l app=tenant-mapper --tail=5 2>/dev/null | grep "$HOST" || echo "")
        if [ ! -z "$TENANT_LOGS" ]; then
            echo "$TENANT_LOGS"
        fi
        
        ((PASSED++))
    else
        echo -e "${RED}✗ Request failed (HTTP $HTTP_CODE)${NC}"
        ((FAILED++))
    fi
    
    echo ""
done

# Cleanup
kill $PF_PID 2>/dev/null || true

# Summary
echo "============================================"
echo "Test Summary / Tổng kết Kiểm tra"
echo "============================================"
echo -e "Passed / Thành công: ${GREEN}$PASSED${NC}"
echo -e "Failed / Thất bại: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! / Tất cả tests đã pass!${NC}"
    echo ""
    echo -e "${BLUE}Tip: Check tenant-mapper logs for detailed flow:${NC}"
    echo -e "${BLUE}Mẹo: Kiểm tra logs tenant-mapper để xem chi tiết:${NC}"
    echo "  kubectl logs -n $NAMESPACE -l app=tenant-mapper -f"
    exit 0
else
    echo -e "${RED}Some tests failed! / Một số tests thất bại!${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting steps:${NC}"
    echo -e "${YELLOW}Các bước khắc phục:${NC}"
    echo "  1. Check if tenant-mapper is running:"
    echo "     kubectl get pods -n $NAMESPACE -l app=tenant-mapper"
    echo "  2. Check tenant-mapper logs:"
    echo "     kubectl logs -n $NAMESPACE -l app=tenant-mapper"
    echo "  3. Verify Redis has domain mappings:"
    echo "     kubectl port-forward -n $NAMESPACE statefulset/redis 6379:6379"
    echo "     redis-cli -a \$REDIS_PASSWORD KEYS 'domain:*'"
    exit 1
fi
