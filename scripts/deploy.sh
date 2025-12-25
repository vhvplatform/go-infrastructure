#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="saas-framework-${ENVIRONMENT}"

echo "🚀 Deploying to ${ENVIRONMENT} environment..."
echo "📦 Namespace: ${NAMESPACE}"
echo ""

# Validate manifests first
echo "🔍 Validating manifests..."
./scripts/validate-manifests.sh ${ENVIRONMENT}

# Choose deployment method
DEPLOY_METHOD=${2:-kustomize}

if [ "$DEPLOY_METHOD" == "kustomize" ]; then
    echo "📝 Deploying with Kustomize..."
    kubectl apply -k kubernetes/overlays/${ENVIRONMENT}
    
elif [ "$DEPLOY_METHOD" == "helm" ]; then
    echo "📝 Deploying with Helm..."
    helm upgrade --install saas-platform helm/charts/saas-platform \
        -f helm/charts/saas-platform/values.${ENVIRONMENT}.yaml \
        --namespace ${NAMESPACE} \
        --create-namespace \
        --wait \
        --timeout 10m
    
elif [ "$DEPLOY_METHOD" == "argocd" ]; then
    echo "📝 Deploying with ArgoCD..."
    kubectl apply -f argocd/applications/${ENVIRONMENT}/
    
    # Wait for ArgoCD sync
    echo "⏳ Waiting for ArgoCD sync..."
    kubectl wait --for=condition=Synced \
        application/go-infrastructure-${ENVIRONMENT} \
        -n argocd \
        --timeout=10m
else
    echo "❌ Invalid deployment method: ${DEPLOY_METHOD}"
    echo "   Valid options: kustomize, helm, argocd"
    exit 1
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Checking deployment status..."
kubectl get pods -n ${NAMESPACE}

echo ""
echo "📝 To check logs, run:"
echo "   kubectl logs -f -n ${NAMESPACE} -l app=<service-name>"
echo ""
echo "📊 To check services, run:"
echo "   kubectl get svc -n ${NAMESPACE}"
