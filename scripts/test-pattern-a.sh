#!/bin/bash
# test-pattern-a.sh - Test Pattern A (Subfolder routing)
# Kiểm tra Mô hình A (Định tuyến thư mục con)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "Testing Pattern A: Subfolder Routing"
echo "Kiểm tra Mô hình A: Định tuyến Thư mục con"
echo "=================================="
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

# Test cases
TEST_CASES=(
    "tenant-123:saas.local:/tenant-123/api/health"
    "tenant-456:saas.local:/tenant-456/api/users"
    "tenant-789:saas.local:/tenant-789/api/tenants"
)

echo ""
echo "Running tests / Chạy kiểm tra..."
echo ""

PASSED=0
FAILED=0

for test in "${TEST_CASES[@]}"; do
    IFS=':' read -r EXPECTED_TENANT HOST PATH <<< "$test"
    
    echo "Test: $HOST$PATH"
    echo "Expected Tenant ID / Tenant ID mong đợi: $EXPECTED_TENANT"
    
    # Make request with curl
    RESPONSE=$(curl -s -H "Host: $HOST" \
        -w "\nHTTP_CODE:%{http_code}" \
        "http://$INGRESS_IP$PATH" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
    
    # Check if request succeeded
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "404" ]; then
        echo -e "${GREEN}✓ Request successful (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Request failed (HTTP $HTTP_CODE)${NC}"
        ((FAILED++))
    fi
    
    echo "Response:"
    echo "$RESPONSE" | grep -v "HTTP_CODE:"
    echo ""
done

# Summary
echo "=================================="
echo "Test Summary / Tổng kết Kiểm tra"
echo "=================================="
echo -e "Passed / Thành công: ${GREEN}$PASSED${NC}"
echo -e "Failed / Thất bại: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! / Tất cả tests đã pass!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! / Một số tests thất bại!${NC}"
    exit 1
fi
