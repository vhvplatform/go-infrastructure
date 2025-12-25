#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="saas-framework-${ENVIRONMENT}"
SECRET_NAME="saas-secrets"

echo "🔐 Secret Management for ${ENVIRONMENT}"
echo "📦 Namespace: ${NAMESPACE}"
echo ""

# Function to create secret from template
create_secret() {
    echo "📝 Creating secret from template..."
    
    if [ ! -f "kubernetes/base/secrets/secrets.template.yaml" ]; then
        echo "❌ Template file not found: kubernetes/base/secrets/secrets.template.yaml"
        exit 1
    fi
    
    # Copy template
    cp kubernetes/base/secrets/secrets.template.yaml /tmp/secrets-${ENVIRONMENT}.yaml
    
    # Update namespace
    sed -i "s/namespace: saas-framework/namespace: ${NAMESPACE}/g" /tmp/secrets-${ENVIRONMENT}.yaml
    
    echo "⚠️  Please edit /tmp/secrets-${ENVIRONMENT}.yaml and replace placeholder values"
    echo "   Press Enter when done..."
    read
    
    # Apply secret
    kubectl apply -f /tmp/secrets-${ENVIRONMENT}.yaml
    
    # Clean up
    rm -f /tmp/secrets-${ENVIRONMENT}.yaml
    
    echo "✅ Secret created successfully"
}

# Function to update secret
update_secret() {
    local key=$1
    local value=$2
    
    if [ -z "$key" ] || [ -z "$value" ]; then
        echo "Usage: update <key> <value>"
        exit 1
    fi
    
    echo "📝 Updating secret ${key}..."
    kubectl patch secret ${SECRET_NAME} \
        -n ${NAMESPACE} \
        -p "{\"stringData\":{\"${key}\":\"${value}\"}}"
    
    echo "✅ Secret updated successfully"
}

# Function to view secret (base64 decoded)
view_secret() {
    local key=$1
    
    if [ -z "$key" ]; then
        echo "📋 Available secrets:"
        kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data}' | jq 'keys'
    else
        echo "🔍 Secret value for ${key}:"
        kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data.${key}}" | base64 -d
        echo ""
    fi
}

# Function to delete secret
delete_secret() {
    read -p "Are you sure you want to delete the secret? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Deletion cancelled"
        exit 0
    fi
    
    kubectl delete secret ${SECRET_NAME} -n ${NAMESPACE}
    echo "✅ Secret deleted successfully"
}

# Main menu
case "${2}" in
    create)
        create_secret
        ;;
    update)
        update_secret "${3}" "${4}"
        ;;
    view)
        view_secret "${3}"
        ;;
    delete)
        delete_secret
        ;;
    *)
        echo "Usage: $0 <environment> <action> [args]"
        echo ""
        echo "Actions:"
        echo "  create              - Create secret from template"
        echo "  update <key> <val>  - Update a secret key"
        echo "  view [key]          - View secret (all keys or specific key)"
        echo "  delete              - Delete the secret"
        echo ""
        echo "Examples:"
        echo "  $0 dev create"
        echo "  $0 dev update JWT_SECRET 'new-secret-value'"
        echo "  $0 dev view JWT_SECRET"
        echo "  $0 dev view"
        echo "  $0 dev delete"
        exit 1
        ;;
esac
