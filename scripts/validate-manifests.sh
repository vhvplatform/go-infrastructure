#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    exit 1
fi

echo "🔍 Validating Kubernetes manifests for ${ENVIRONMENT}..."
echo ""

# Check if required tools are installed
command -v kustomize >/dev/null 2>&1 || {
    echo "❌ kustomize is not installed. Please install it first."
    echo "   https://kubectl.docs.kubernetes.io/installation/kustomize/"
    exit 1
}

# Validate Kustomize overlays
echo "📝 Validating Kustomize overlay..."
if [ -d "kubernetes/overlays/${ENVIRONMENT}" ]; then
    kustomize build kubernetes/overlays/${ENVIRONMENT} > /tmp/manifests-${ENVIRONMENT}.yaml
    echo "✅ Kustomize build successful"
else
    echo "❌ Overlay directory not found: kubernetes/overlays/${ENVIRONMENT}"
    exit 1
fi

# Validate with kubectl (requires cluster connection)
if kubectl cluster-info >/dev/null 2>&1; then
    echo "📝 Validating manifests with kubectl..."
    kubectl apply -f /tmp/manifests-${ENVIRONMENT}.yaml --dry-run=client
    echo "✅ kubectl validation successful"
else
    echo "⚠️  No Kubernetes cluster connection, skipping kubectl validation"
fi

# Check for kubeval if available
if command -v kubeval >/dev/null 2>&1; then
    echo "📝 Validating with kubeval..."
    kubeval --strict /tmp/manifests-${ENVIRONMENT}.yaml
    echo "✅ kubeval validation successful"
else
    echo "⚠️  kubeval not installed, skipping strict validation"
    echo "   Install: curl -sSL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xz"
fi

# Validate Helm charts if they exist
if [ -d "helm/charts/saas-platform" ]; then
    if command -v helm >/dev/null 2>&1; then
        echo "📝 Validating Helm charts..."
        helm lint helm/charts/saas-platform
        helm lint helm/charts/infrastructure
        helm lint helm/charts/microservices
        
        echo "📝 Validating Helm template..."
        helm template test helm/charts/saas-platform \
            -f helm/charts/saas-platform/values.${ENVIRONMENT}.yaml \
            > /tmp/helm-manifests-${ENVIRONMENT}.yaml
        echo "✅ Helm validation successful"
    else
        echo "⚠️  helm not installed, skipping Helm validation"
    fi
fi

# Clean up
rm -f /tmp/manifests-${ENVIRONMENT}.yaml /tmp/helm-manifests-${ENVIRONMENT}.yaml

echo ""
echo "✅ All manifests are valid for ${ENVIRONMENT} environment!"
