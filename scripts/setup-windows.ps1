# =============================================================================
# Windows Setup Script for Go Infrastructure Repository
# =============================================================================
# This script automates the installation of dependencies, configuration of
# environment variables, and initialization of services required for development
# on Windows systems.
# =============================================================================

#Requires -Version 5.1

# Set error action preference
$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Detect Windows version
function Get-WindowsVersion {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    Write-Info "Detected OS: $($osInfo.Caption) (Build $($osInfo.BuildNumber))"
    
    if ($osInfo.BuildNumber -lt 19041) {
        Write-Warning "Windows 10 version 2004 (build 19041) or higher is recommended for optimal Docker support."
    }
    
    return $osInfo
}

# Check if a command exists
function Test-Command {
    param([string]$Command)
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Install Chocolatey
function Install-Chocolatey {
    if (Test-Command "choco") {
        Write-Success "Chocolatey is already installed"
        return
    }
    
    Write-Info "Installing Chocolatey package manager..."
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Success "Chocolatey installed successfully"
    }
    catch {
        Write-Error "Failed to install Chocolatey: $_"
        Write-Info "Please install Chocolatey manually from https://chocolatey.org/install"
        exit 1
    }
}

# Install Git
function Install-Git {
    if (Test-Command "git") {
        $gitVersion = (git --version) -replace '[^0-9.]', ''
        Write-Success "Git is already installed (version: $gitVersion)"
        return
    }
    
    Write-Info "Installing Git for Windows..."
    
    try {
        choco install git -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "Git installed successfully"
    }
    catch {
        Write-Error "Failed to install Git: $_"
    }
}

# Check Docker Desktop
function Test-Docker {
    if (Test-Command "docker") {
        $dockerVersion = docker --version
        Write-Success "Docker is already installed ($dockerVersion)"
        
        # Test if Docker daemon is running
        try {
            docker ps | Out-Null
            Write-Success "Docker daemon is running"
            return $true
        }
        catch {
            Write-Warning "Docker is installed but daemon is not running. Please start Docker Desktop."
            return $false
        }
    }
    
    Write-Warning "Docker Desktop is not installed"
    Write-Info "Please install Docker Desktop manually:"
    Write-Info "  1. Download from: https://www.docker.com/products/docker-desktop/"
    Write-Info "  2. Run the installer"
    Write-Info "  3. Enable WSL 2 backend"
    Write-Info "  4. Restart your computer"
    Write-Info "  5. Start Docker Desktop"
    Write-Info ""
    Write-Info "Or install via Chocolatey:"
    Write-Info "  choco install docker-desktop -y"
    
    return $false
}

# Install kubectl
function Install-Kubectl {
    if (Test-Command "kubectl") {
        $kubectlVersion = (kubectl version --client --short 2>$null) -replace '[^0-9.]', ''
        Write-Success "kubectl is already installed (version: $kubectlVersion)"
        return
    }
    
    Write-Info "Installing kubectl..."
    
    try {
        choco install kubernetes-cli -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "kubectl installed successfully"
    }
    catch {
        Write-Error "Failed to install kubectl: $_"
    }
}

# Install Helm
function Install-Helm {
    if (Test-Command "helm") {
        $helmVersion = (helm version --short 2>$null) -replace '[^0-9.]', ''
        Write-Success "Helm is already installed (version: $helmVersion)"
        return
    }
    
    Write-Info "Installing Helm..."
    
    try {
        choco install kubernetes-helm -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "Helm installed successfully"
    }
    catch {
        Write-Error "Failed to install Helm: $_"
    }
}

# Install Kustomize
function Install-Kustomize {
    if (Test-Command "kustomize") {
        $kustomizeVersion = (kustomize version --short 2>$null) -replace '[^0-9.]', ''
        Write-Success "kustomize is already installed (version: $kustomizeVersion)"
        return
    }
    
    Write-Info "Installing kustomize..."
    
    try {
        choco install kustomize -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "kustomize installed successfully"
    }
    catch {
        Write-Error "Failed to install kustomize: $_"
    }
}

# Install Terraform
function Install-Terraform {
    if (Test-Command "terraform") {
        $terraformVersion = (terraform version -json 2>$null | ConvertFrom-Json).terraform_version
        if (-not $terraformVersion) {
            $terraformVersion = (terraform version) -replace '[^0-9.]', ''
        }
        Write-Success "Terraform is already installed (version: $terraformVersion)"
        return
    }
    
    Write-Info "Installing Terraform..."
    
    try {
        choco install terraform -y
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "Terraform installed successfully"
    }
    catch {
        Write-Error "Failed to install Terraform: $_"
    }
}

# Install Go
function Install-Go {
    if (Test-Command "go") {
        $goVersion = (go version) -replace '[^0-9.]', ''
        Write-Success "Go is already installed (version: $goVersion)"
        return
    }
    
    # Match version with go.mod requirement (1.21)
    $goVersion = "1.21"
    Write-Info "Installing Go $goVersion..."
    
    try {
        # Install latest 1.21.x version
        choco install golang --version=$goVersion -y
        
        # Set up Go environment variables
        $goPath = "$env:USERPROFILE\go"
        [Environment]::SetEnvironmentVariable("GOPATH", $goPath, [EnvironmentVariableTarget]::User)
        
        # Add Go to PATH
        $goBin = "C:\Program Files\Go\bin"
        $goUserBin = "$goPath\bin"
        $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
        
        # Update PATH if needed (check both directories before updating)
        $pathUpdated = $false
        $newPath = $currentPath
        
        if ($currentPath -notlike "*$goBin*") {
            $newPath = "$newPath;$goBin"
            $pathUpdated = $true
        }
        if ($currentPath -notlike "*$goUserBin*") {
            $newPath = "$newPath;$goUserBin"
            $pathUpdated = $true
        }
        
        if ($pathUpdated) {
            [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
        }
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $env:GOPATH = $goPath
        
        Write-Success "Go installed successfully"
    }
    catch {
        Write-Error "Failed to install Go: $_"
    }
}

# Install Google Cloud SDK (optional)
function Install-GCloud {
    if (Test-Command "gcloud") {
        $gcloudVersion = (gcloud version --format="value(version)" 2>$null)
        Write-Success "Google Cloud SDK is already installed (version: $gcloudVersion)"
        return
    }
    
    Write-Info "Google Cloud SDK is not installed"
    Write-Info "To install Google Cloud SDK:"
    Write-Info "  Option 1: choco install gcloudsdk -y"
    Write-Info "  Option 2: Download from https://cloud.google.com/sdk/docs/install"
    Write-Warning "Skipping Google Cloud SDK installation (optional)"
}

# Setup environment configuration
function Initialize-Environment {
    Write-Info "Setting up environment configuration..."
    
    $envFile = ".env"
    
    if (Test-Path $envFile) {
        Write-Success ".env file already exists"
        return
    }
    
    Write-Info "Creating .env file from template..."
    
    $envContent = @"
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
"@
    
    try {
        # Write with default line ending (adds newline at end)
        $envContent | Out-File -FilePath $envFile -Encoding utf8
        Write-Success ".env file created. Please configure it with your values."
    }
    catch {
        Write-Error "Failed to create .env file: $_"
    }
}

# Build tenant-mapper service
function Build-TenantMapper {
    Write-Info "Building tenant-mapper service..."
    
    $serviceDir = "services\tenant-mapper"
    
    if (-not (Test-Path $serviceDir)) {
        Write-Warning "tenant-mapper service directory not found at $serviceDir"
        return
    }
    
    Push-Location $serviceDir
    
    try {
        if (Test-Path "go.mod") {
            Write-Info "Downloading Go dependencies..."
            go mod download
            
            Write-Info "Building tenant-mapper..."
            go build -o tenant-mapper.exe main.go
            
            if (Test-Path "tenant-mapper.exe") {
                Write-Success "tenant-mapper service built successfully"
            }
            else {
                Write-Warning "tenant-mapper.exe was not created"
            }
        }
        else {
            Write-Warning "go.mod not found in tenant-mapper service"
        }
    }
    catch {
        Write-Error "Failed to build tenant-mapper: $_"
    }
    finally {
        Pop-Location
    }
}

# Display summary
function Show-Summary {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Info "Installed tools:"
    if (Test-Command "git") { Write-Host "  ✓ Git" -ForegroundColor Green }
    if (Test-Command "docker") { Write-Host "  ✓ Docker" -ForegroundColor Green }
    if (Test-Command "kubectl") { Write-Host "  ✓ kubectl" -ForegroundColor Green }
    if (Test-Command "helm") { Write-Host "  ✓ Helm" -ForegroundColor Green }
    if (Test-Command "kustomize") { Write-Host "  ✓ kustomize" -ForegroundColor Green }
    if (Test-Command "terraform") { Write-Host "  ✓ Terraform" -ForegroundColor Green }
    if (Test-Command "go") { Write-Host "  ✓ Go" -ForegroundColor Green }
    if (Test-Command "gcloud") { Write-Host "  ✓ Google Cloud SDK" -ForegroundColor Green }
    
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Close and reopen your terminal to refresh environment variables"
    Write-Host "  2. Configure .env file with your credentials"
    Write-Host "  3. Start Docker Desktop (if not already running)"
    Write-Host "  4. Authenticate with GCP (if using GCP): gcloud auth login"
    Write-Host "  5. Start local development: docker-compose up -d"
    Write-Host "  6. Deploy using kubectl: kubectl apply -k kubernetes/overlays/dev"
    Write-Host "     Or use bash scripts via Git Bash/WSL: ./scripts/deploy.sh dev"
    Write-Host ""
    Write-Info "For more information, see:"
    Write-Host "  - README.md"
    Write-Host "  - docs\windows-setup.md"
    Write-Host "  - docs\QUICK_START.md"
    Write-Host ""
}

# Main setup function
function Start-Setup {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Go Infrastructure - Windows Setup" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if running as Administrator
    if (-not (Test-Administrator)) {
        Write-Warning "This script should be run as Administrator for best results."
        Write-Info "Some installations may require elevated privileges."
        Write-Host ""
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Info "Please restart PowerShell as Administrator and run this script again."
            exit 0
        }
    }
    
    # Detect Windows version
    Get-WindowsVersion | Out-Null
    Write-Host ""
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Info "PowerShell version: $($psVersion.Major).$($psVersion.Minor)"
    if ($psVersion.Major -lt 5) {
        Write-Warning "PowerShell 5.1 or higher is recommended. Current version: $($psVersion.Major).$($psVersion.Minor)"
    }
    Write-Host ""
    
    Write-Info "Starting dependency installation..."
    Write-Host ""
    
    # Install dependencies
    Install-Chocolatey
    Install-Git
    Test-Docker
    Install-Kubectl
    Install-Helm
    Install-Kustomize
    Install-Terraform
    Install-Go
    Install-GCloud
    
    Write-Host ""
    Initialize-Environment
    
    Write-Host ""
    Build-TenantMapper
    
    Show-Summary
}

# Run the setup
try {
    Start-Setup
}
catch {
    Write-Error "Setup failed with error: $_"
    Write-Host ""
    Write-Info "Please check the error message above and try again."
    Write-Info "For help, see docs\windows-setup.md or open an issue on GitHub."
    exit 1
}
