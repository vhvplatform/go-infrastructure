#!/bin/bash
set -e

ENVIRONMENT=${1}
REVISION=${2}

if [ -z "$ENVIRONMENT" ] || [ -z "$REVISION" ]; then
    echo "Usage: $0 <environment> <revision>"
    echo "Example: $0 production 2"
    exit 1
fi

NAMESPACE="saas-framework-${ENVIRONMENT}"

echo "⏪ Rolling back ${ENVIRONMENT} to revision ${REVISION}..."
echo "📦 Namespace: ${NAMESPACE}"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback ${ENVIRONMENT} to revision ${REVISION}? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Rollback cancelled"
    exit 0
fi

# List deployments
echo "📋 Available deployments:"
kubectl get deployments -n ${NAMESPACE}
echo ""

# Rollback all deployments
for deployment in $(kubectl get deployments -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
    echo "⏪ Rolling back ${deployment}..."
    kubectl rollout undo deployment/${deployment} -n ${NAMESPACE} --to-revision=${REVISION}
done

echo ""
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment -n ${NAMESPACE} --timeout=10m

echo ""
echo "✅ Rollback complete!"
echo ""
echo "📊 Current deployment status:"
kubectl get pods -n ${NAMESPACE}

echo ""
echo "📝 To check rollout history, run:"
echo "   kubectl rollout history deployment/<deployment-name> -n ${NAMESPACE}"
