# Getting Started on Windows

Complete guide for setting up the Go Infrastructure development environment on Windows.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [Automated Setup](#automated-setup)
- [Manual Setup](#manual-setup)
- [Verification](#verification)
- [Local Development](#local-development)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Prerequisites

Before you begin, ensure you have:

- **Windows 10/11** (64-bit) or Windows Server 2019/2022
- **Administrator access** for installing software
- **Stable internet connection** for downloading dependencies
- **At least 8GB RAM** (16GB recommended for Kubernetes development)
- **20GB free disk space** (more recommended for Docker images)

### Required Software

The following tools are required for development:

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| **PowerShell** | 5.1+ | Scripting and automation |
| **Git for Windows** | Latest | Version control |
| **Docker Desktop** | Latest | Container runtime |
| **kubectl** | 1.27+ | Kubernetes CLI |
| **helm** | 3.12+ | Kubernetes package manager |
| **kustomize** | 5.0+ | Kubernetes customization |
| **terraform** | 1.10+ | Infrastructure provisioning |
| **Go** | 1.21+ | Build tenant-mapper service |
| **gcloud CLI** | Latest | Google Cloud management (optional) |

## System Requirements

### Minimum Requirements

- **OS**: Windows 10 (64-bit) version 21H2 or higher, or Windows 11
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disk**: 20GB free space
- **Virtualization**: Intel VT-x or AMD-V enabled in BIOS

### Recommended Requirements

- **OS**: Windows 11 Professional or Enterprise
- **CPU**: 8 cores
- **RAM**: 16GB or more
- **Disk**: 50GB+ free space (SSD recommended)
- **WSL 2**: Windows Subsystem for Linux 2 enabled

### Enable Required Windows Features

For Docker Desktop and WSL 2 support:

```powershell
# Run PowerShell as Administrator
# Enable WSL 2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart your computer
# After restart, set WSL 2 as default
wsl --set-default-version 2
```

## Automated Setup

The quickest way to get started is using our automated PowerShell setup script.

### Quick Start

1. **Clone the repository**:
   ```powershell
   git clone https://github.com/vhvplatform/go-infrastructure.git
   cd go-infrastructure
   ```

2. **Run the setup script** (as Administrator):
   ```powershell
   # Allow script execution (if needed)
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Run the setup script
   .\scripts\setup-windows.ps1
   ```

3. **Follow the prompts** and wait for installation to complete.

The script will:
- ✅ Check system requirements
- ✅ Install Chocolatey package manager (if needed)
- ✅ Install all required dependencies
- ✅ Configure environment variables
- ✅ Build the tenant-mapper service
- ✅ Create `.env` configuration file
- ✅ Verify installations

## Manual Setup

If you prefer to install dependencies manually or the automated script fails:

### Step 1: Install Chocolatey

Chocolatey is a package manager for Windows that simplifies software installation.

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### Step 2: Install Git

```powershell
choco install git -y
# Refresh environment variables
refreshenv
```

Or download from: https://git-scm.com/download/win

### Step 3: Install Docker Desktop

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Run the installer
3. Enable WSL 2 backend during installation
4. Restart your computer after installation
5. Start Docker Desktop and complete initial setup

Alternatively, using Chocolatey:
```powershell
choco install docker-desktop -y
```

### Step 4: Install Kubernetes Tools

```powershell
# Install kubectl
choco install kubernetes-cli -y

# Install helm
choco install kubernetes-helm -y

# Install kustomize
choco install kustomize -y
```

Alternatively, download binaries manually:
- kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- helm: https://github.com/helm/helm/releases
- kustomize: https://github.com/kubernetes-sigs/kustomize/releases

### Step 5: Install Terraform

```powershell
choco install terraform -y
```

Or download from: https://www.terraform.io/downloads

### Step 6: Install Go

```powershell
choco install golang --version=1.21.5 -y
```

Or download from: https://go.dev/dl/

### Step 7: Install Google Cloud SDK (Optional)

For GCP deployments:

```powershell
choco install gcloudsdk -y
```

Or download from: https://cloud.google.com/sdk/docs/install

### Step 8: Configure Environment Variables

Add tools to your PATH if not already added:

```powershell
# Run as Administrator
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Go\bin", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("GOPATH", "$env:USERPROFILE\go", [EnvironmentVariableTarget]::User)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\go\bin", [EnvironmentVariableTarget]::User)
```

### Step 9: Clone Repository

```powershell
git clone https://github.com/vhvplatform/go-infrastructure.git
cd go-infrastructure
```

### Step 10: Create Environment Configuration

```powershell
# Create .env file
@"
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
"@ | Out-File -FilePath .env -Encoding utf8
```

### Step 11: Build Tenant Mapper Service

```powershell
cd services\tenant-mapper
go mod download
go build -o tenant-mapper.exe main.go
cd ..\..
```

## Verification

Verify all tools are installed correctly:

```powershell
# Check versions
Write-Host "=== Verifying Installations ===" -ForegroundColor Green

Write-Host "`nGit:" -ForegroundColor Yellow
git --version

Write-Host "`nDocker:" -ForegroundColor Yellow
docker --version
docker ps

Write-Host "`nKubectl:" -ForegroundColor Yellow
kubectl version --client

Write-Host "`nHelm:" -ForegroundColor Yellow
helm version

Write-Host "`nKustomize:" -ForegroundColor Yellow
kustomize version

Write-Host "`nTerraform:" -ForegroundColor Yellow
terraform version

Write-Host "`nGo:" -ForegroundColor Yellow
go version

Write-Host "`nGoogle Cloud SDK (if installed):" -ForegroundColor Yellow
gcloud --version

Write-Host "`n=== Verification Complete ===" -ForegroundColor Green
```

## Local Development

### Starting Services with Docker Compose

```powershell
# Start all services
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs -f

# Access specific service logs
docker-compose logs -f tenant-mapper

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Building the Tenant Mapper

```powershell
# Navigate to service directory
cd services\tenant-mapper

# Download dependencies
go mod download

# Build for Windows
go build -o tenant-mapper.exe main.go

# Build for Linux (cross-compilation)
$env:GOOS="linux"; $env:GOARCH="amd64"; go build -o tenant-mapper main.go
Remove-Item Env:\GOOS
Remove-Item Env:\GOARCH

# Run locally
.\tenant-mapper.exe
```

### Building Docker Images

```powershell
# Development image
docker build -f Dockerfile.dev -t tenant-mapper:dev .

# Production image
docker build -t tenant-mapper:prod .

# Run container
docker run -p 8080:80 tenant-mapper:dev
```

### Testing the Setup

```powershell
# Test tenant-mapper service
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing

# Test Redis
docker-compose exec redis redis-cli ping

# Store test data in Redis
docker-compose exec redis redis-cli SET "domain:example.com" "tenant-123"

# Retrieve test data
docker-compose exec redis redis-cli GET "domain:example.com"

# View Grafana (if monitoring stack is running)
Start-Process "http://localhost:3000"  # Default: admin/admin

# View Prometheus
Start-Process "http://localhost:9090"
```

## Troubleshooting

### Common Issues and Solutions

#### PowerShell Execution Policy Error

**Issue**: Script execution is disabled on this system.

**Solution**:
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Docker Desktop Not Starting

**Issue**: Docker Desktop fails to start or shows "Docker engine not running".

**Solutions**:
1. Ensure virtualization is enabled in BIOS
2. Check WSL 2 is installed and set as default:
   ```powershell
   wsl --set-default-version 2
   ```
3. Reset Docker Desktop:
   - Right-click Docker Desktop tray icon
   - Select "Troubleshoot" → "Reset to factory defaults"
4. Restart Docker Desktop from Start menu

#### WSL 2 Installation Issues

**Issue**: WSL 2 installation fails or not available.

**Solution**:
```powershell
# Update WSL
wsl --update

# Install Ubuntu (or your preferred distribution)
wsl --install -d Ubuntu

# Set as default version
wsl --set-default-version 2
```

#### Port Already in Use

**Issue**: Error binding to port (e.g., 8080 already in use).

**Solution**:
```powershell
# Find process using the port
netstat -ano | findstr :8080

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F

# Or change port in docker-compose.yml
```

#### Chocolatey Command Not Found

**Issue**: `choco` command not recognized after installation.

**Solution**:
```powershell
# Refresh environment variables
refreshenv

# Or close and reopen PowerShell/Terminal

# Or add manually to PATH
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
```

#### Go Build Fails

**Issue**: `go build` command fails with module errors.

**Solution**:
```powershell
# Clear Go module cache
go clean -modcache

# Re-download dependencies
go mod download

# Verify go.mod
go mod verify

# Try building again
go build -o tenant-mapper.exe main.go
```

#### Git Line Ending Issues

**Issue**: Git reports file changes due to line endings (CRLF vs LF).

**Solution**:
```powershell
# Configure Git to handle line endings automatically
git config --global core.autocrlf true

# For repository
git config core.autocrlf true
```

#### Permission Denied Errors

**Issue**: Access denied when installing tools or running scripts.

**Solutions**:
1. Run PowerShell or Terminal as Administrator
2. Check antivirus/Windows Defender isn't blocking installation
3. Temporarily disable real-time protection during installation

#### Kubernetes Connection Issues

**Issue**: Cannot connect to Kubernetes cluster.

**Solution**:
```powershell
# Verify Docker Desktop Kubernetes is enabled
# Settings → Kubernetes → Enable Kubernetes

# Check kubectl config
kubectl config view

# Switch context if needed
kubectl config get-contexts
kubectl config use-context docker-desktop
```

#### Terraform Initialization Fails

**Issue**: Terraform init fails with provider errors.

**Solution**:
```powershell
# Clear Terraform cache
Remove-Item -Recurse -Force .terraform

# Delete lock file
Remove-Item .terraform.lock.hcl -ErrorAction SilentlyContinue

# Re-initialize
terraform init
```

### Docker Memory Issues

**Issue**: Docker runs out of memory or containers crash.

**Solution**:
1. Open Docker Desktop Settings
2. Go to Resources → Advanced
3. Increase Memory allocation (recommend 4GB minimum, 8GB for development)
4. Increase CPUs (recommend 4+)
5. Click "Apply & Restart"

### Networking Issues

**Issue**: Cannot access services or download packages.

**Solutions**:
```powershell
# Check DNS resolution
nslookup google.com

# Flush DNS cache
ipconfig /flushdns

# Reset network stack (as Administrator)
netsh winsock reset
netsh int ip reset

# Restart computer after network reset
```

### Getting Additional Help

If you encounter issues not covered here:

1. **Check logs**:
   - Docker Desktop logs: Settings → Troubleshoot → Show logs
   - Application logs: `docker-compose logs -f`
   
2. **Review documentation**:
   - [Main README](../README.md)
   - [Troubleshooting Guide](TROUBLESHOOTING.md)
   - [Quick Start Guide](QUICK_START.md)

3. **Search existing issues**: 
   - [GitHub Issues](https://github.com/vhvplatform/go-infrastructure/issues)

4. **Contact support**:
   - 📧 Email: team@saas-framework.io
   - 💬 Slack: #go-infrastructure
   - 🐛 [Open new issue](https://github.com/vhvplatform/go-infrastructure/issues/new)

## Next Steps

After successful setup:

### 1. Local Development

```powershell
# Start the local development environment
docker-compose up -d

# View logs
docker-compose logs -f
```

### 2. Cloud Deployment

For cloud deployments, see:
- **GCP**: [Quick Start Guide - Path 2](QUICK_START.md#path-2-cloud-deployment-on-gcp)
- **AWS**: [Quick Start Guide - Path 3](QUICK_START.md#path-3-cloud-deployment-on-aws)

### 3. Learn the Architecture

- [Architecture Overview](ARCHITECTURE.md)
- [Hybrid Multi-tenant Deployment](HYBRID_MULTITENANT_DEPLOYMENT.md)
- [Traffic Flow Architecture](TRAFFIC_FLOW_ARCHITECTURE.md)

### 4. Deploy Applications

```powershell
# Deploy to development environment
.\scripts\deploy.sh dev

# Or using kubectl and kustomize
kubectl apply -k kubernetes/overlays/dev

# Check deployment status
kubectl get all -n saas-framework-dev
```

### 5. Set Up Monitoring

```powershell
# Deploy monitoring stack
kubectl apply -k monitoring/

# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Access Grafana at http://localhost:3000
```

### 6. Configure GitOps

```powershell
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy applications
kubectl apply -f argocd/app-of-apps.yaml

# Port-forward ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Additional Resources

### Documentation

- [Main README](../README.md) - Complete project overview
- [Contributing Guide](../CONTRIBUTING.md) - How to contribute
- [Deployment Guide](DEPLOYMENT.md) - Detailed deployment instructions
- [GitOps Workflow](GITOPS.md) - GitOps best practices

### Windows-Specific Tools

- **Windows Terminal**: Modern terminal for Windows - [Download](https://aka.ms/terminal)
- **WSL 2**: Run Linux on Windows - [Install Guide](https://docs.microsoft.com/en-us/windows/wsl/install)
- **Visual Studio Code**: Recommended IDE - [Download](https://code.visualstudio.com/)
- **PowerShell 7**: Modern PowerShell - [Download](https://github.com/PowerShell/PowerShell/releases)

### Community

- 💬 [Slack Channel](https://slack.com) - #go-infrastructure
- 📧 [Mailing List](mailto:team@saas-framework.io)
- 🐛 [Issue Tracker](https://github.com/vhvplatform/go-infrastructure/issues)
- 📖 [Wiki](https://github.com/vhvplatform/go-infrastructure/wiki)

## Feedback

We'd love to hear your feedback on the Windows setup experience! If you encounter any issues or have suggestions for improvement:

1. Open an issue on [GitHub](https://github.com/vhvplatform/go-infrastructure/issues)
2. Tag it with `windows` and `documentation` labels
3. Include your Windows version and any error messages

Thank you for using go-infrastructure! 🚀
