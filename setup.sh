#!/bin/bash

# =============================================================================
# Setup Script for Go Infrastructure Repository
# =============================================================================
# This script automates the installation of dependencies, configuration of
# environment variables, and initialization of services required for development.
# Compatible with Linux and macOS.
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected OS: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected OS: macOS"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install kubectl
install_kubectl() {
    if command_exists kubectl; then
        KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+' || echo "unknown")
        log_success "kubectl is already installed (version: $KUBECTL_VERSION)"
        return
    fi
    
    log_info "Installing kubectl..."
    if [[ "$OS" == "linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/kubectl
        fi
    fi
    log_success "kubectl installed successfully"
}

# Check and install kustomize
install_kustomize() {
    if command_exists kustomize; then
        KUSTOMIZE_VERSION=$(kustomize version --short 2>/dev/null || echo "unknown")
        log_success "kustomize is already installed (version: $KUSTOMIZE_VERSION)"
        return
    fi
    
    log_info "Installing kustomize..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize /usr/local/bin/
    log_success "kustomize installed successfully"
}

# Check and install Helm
install_helm() {
    if command_exists helm; then
        HELM_VERSION=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Helm is already installed (version: $HELM_VERSION)"
        return
    fi
    
    log_info "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_success "Helm installed successfully"
}

# Check and install Terraform
install_terraform() {
    if command_exists terraform; then
        TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | grep -oP '"terraform_version":"\K[^"]+' || terraform version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Terraform is already installed (version: $TERRAFORM_VERSION)"
        return
    fi
    
    log_info "Installing Terraform..."
    if [[ "$OS" == "linux" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install -y terraform
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            log_error "Homebrew is required to install Terraform on macOS. Please install Homebrew first."
            exit 1
        fi
    fi
    log_success "Terraform installed successfully"
}

# Check and install gcloud CLI
install_gcloud() {
    if command_exists gcloud; then
        GCLOUD_VERSION=$(gcloud version --format="value(version)" 2>/dev/null || echo "unknown")
        log_success "gcloud CLI is already installed (version: $GCLOUD_VERSION)"
        return
    fi
    
    log_info "Installing gcloud CLI..."
    if [[ "$OS" == "linux" ]]; then
        curl https://sdk.cloud.google.com | bash
        exec -l $SHELL
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install --cask google-cloud-sdk
        else
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        fi
    fi
    log_success "gcloud CLI installed successfully"
}

# Check and install Go
install_go() {
    if command_exists go; then
        GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Go is already installed (version: $GO_VERSION)"
        return
    fi
    
    log_info "Installing Go..."
    GO_VERSION="1.21.5"  # Match version with Dockerfiles and go.mod
    if [[ "$OS" == "linux" ]]; then
        wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
        rm "go${GO_VERSION}.linux-amd64.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install go
        else
            wget "https://go.dev/dl/go${GO_VERSION}.darwin-amd64.tar.gz"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "go${GO_VERSION}.darwin-amd64.tar.gz"
            rm "go${GO_VERSION}.darwin-amd64.tar.gz"
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
            export PATH=$PATH:/usr/local/go/bin
        fi
    fi
    log_success "Go installed successfully"
}

# Check and install Docker
install_docker() {
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_success "Docker is already installed (version: $DOCKER_VERSION)"
        return
    fi
    
    log_info "Installing Docker..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        sudo usermod -aG docker $USER
        log_warning "Please log out and back in for Docker group changes to take effect"
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install --cask docker
            log_warning "Please start Docker Desktop from Applications"
        else
            log_error "Please install Docker Desktop for macOS from https://www.docker.com/products/docker-desktop"
            exit 1
        fi
    fi
    log_success "Docker installed successfully"
}

# Check and install Docker Compose
install_docker_compose() {
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose is already installed"
        return
    fi
    
    log_info "Installing Docker Compose..."
    if [[ "$OS" == "linux" ]]; then
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    elif [[ "$OS" == "macos" ]]; then
        # Docker Desktop includes Docker Compose
        log_info "Docker Compose is included with Docker Desktop"
    fi
    log_success "Docker Compose installed successfully"
}

# Setup environment configuration
setup_environment() {
    log_info "Setting up environment configuration..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        log_info "Creating .env file from template..."
        cat > .env << 'EOF'
# Environment Configuration
ENVIRONMENT=dev

# GCP Configuration
GCP_PROJECT_ID=
GCP_REGION=us-central1
GCP_ZONE=us-central1-a

# MongoDB Atlas Configuration
MONGODB_ATLAS_PUBLIC_KEY=
MONGODB_ATLAS_PRIVATE_KEY=
MONGODB_ATLAS_ORG_ID=

# Redis Configuration
REDIS_ADDR=redis:6379
REDIS_PASSWORD=

# Application Configuration
NAMESPACE=saas-framework-dev
CLUSTER_NAME=saas-framework-dev

# Docker Registry
DOCKER_REGISTRY=gcr.io
IMAGE_TAG=latest
EOF
        log_success ".env file created. Please configure it with your values."
    else
        log_success ".env file already exists"
    fi
}

# Build tenant-mapper service
build_tenant_mapper() {
    log_info "Building tenant-mapper service..."
    
    if [ -d "server/tenant-mapper" ]; then
        cd server/tenant-mapper
        if [ -f "go.mod" ]; then
            go mod download
            go build -o tenant-mapper main.go
            log_success "tenant-mapper service built successfully"
        else
            log_warning "go.mod not found in tenant-mapper service"
        fi
        cd ../..
    else
        log_warning "tenant-mapper service directory not found"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "  Setup Complete!"
    echo "=========================================="
    echo ""
    log_info "Installed tools:"
    command_exists kubectl && echo "  ✓ kubectl"
    command_exists kustomize && echo "  ✓ kustomize"
    command_exists helm && echo "  ✓ helm"
    command_exists terraform && echo "  ✓ terraform"
    command_exists gcloud && echo "  ✓ gcloud"
    command_exists go && echo "  ✓ go"
    command_exists docker && echo "  ✓ docker"
    (command_exists docker-compose || docker compose version >/dev/null 2>&1) && echo "  ✓ docker-compose"
    echo ""
    log_info "Next steps:"
    echo "  1. Configure .env file with your credentials"
    echo "  2. Authenticate with GCP: gcloud auth login"
    echo "  3. Configure kubectl: gcloud container clusters get-credentials <cluster-name>"
    echo "  4. Deploy infrastructure: ./scripts/deploy.sh dev"
    echo ""
    log_info "For more information, see README.md"
}

# Main installation flow
main() {
    echo "=========================================="
    echo "  Go Infrastructure Setup"
    echo "=========================================="
    echo ""
    
    detect_os
    
    log_info "Starting dependency installation..."
    echo ""
    
    install_kubectl
    install_kustomize
    install_helm
    install_terraform
    install_gcloud
    install_go
    install_docker
    install_docker_compose
    
    echo ""
    setup_environment
    
    echo ""
    build_tenant_mapper
    
    display_summary
}

# Run main function
main
