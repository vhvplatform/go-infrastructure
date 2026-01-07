# Repository Restructure - Git Commands

## Overview

The repository has been successfully restructured with the following new directory layout:

- **client/** - ReactJS frontend microservices
- **server/** - Golang backend microservices (moved from `services/`)
- **flutter/** - Flutter mobile applications
- **docs/** - Project documentation (unchanged)

Infrastructure directories (kubernetes/, helm/, terraform/, argocd/, monitoring/) remain at the root level.

## Git Checkout Commands

### 1. For existing cloned repository (updating to new structure):

```bash
# Navigate to your existing repository
cd go-infrastructure

# Fetch latest changes from remote
git fetch origin

# Checkout the updated branch
git checkout copilot/update-repository-structure

# Pull latest changes
git pull origin copilot/update-repository-structure
```

### 2. For new clone (fresh checkout):

```bash
# Clone the repository
git clone https://github.com/vhvplatform/go-infrastructure.git

# Navigate to the repository
cd go-infrastructure

# Checkout the restructured branch
git checkout copilot/update-repository-structure
```

## Alternative: Clone specific branch directly

```bash
# Clone only the specific branch
git clone --branch copilot/update-repository-structure https://github.com/vhvplatform/go-infrastructure.git

# Navigate to the repository
cd go-infrastructure
```

## Verification

After checking out, verify the new structure:

```bash
# List the new directory structure
ls -la

# You should see:
# - client/    (new)
# - server/    (replaces services/)
# - flutter/   (new)
# - docs/
# - kubernetes/
# - helm/
# - terraform/
# - argocd/
# - monitoring/
# - scripts/
```

## Changes Summary

### What Changed:

1. **Directory Restructure:**
   - Moved `services/middleware/` → `server/middleware/`
   - Moved `services/tenant-mapper/` → `server/tenant-mapper/`
   - Created `client/` directory with README
   - Created `flutter/` directory with README
   - Created `server/` directory with README
   - Removed empty `services/` directory

2. **Updated Files:**
   - `Dockerfile` - Updated paths from `services/` to `server/`
   - `Dockerfile.dev` - Updated paths from `services/` to `server/`
   - `docker-compose.yml` - Updated build context paths
   - `setup.sh` - Updated tenant-mapper build path
   - `README.md` - Updated repository structure documentation
   - `server/middleware/go.mod` - Updated module path
   - `server/tenant-mapper/go.mod` - Updated module path
   - Documentation files in `docs/` - Updated path references

3. **Testing:**
   - ✅ Docker Compose configuration validated
   - ✅ Go builds successful for all services
   - ✅ Module dependencies resolved

## Working with the New Structure

### Building Services:

```bash
# Build tenant-mapper
cd server/tenant-mapper
go build -o tenant-mapper main.go

# Build with Docker Compose
docker compose build tenant-mapper
```

### Starting Development Environment:

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d tenant-mapper
```

## Need Help?

- See `client/README.md` for frontend development guide
- See `server/README.md` for backend development guide
- See `flutter/README.md` for mobile app development guide
- See main `README.md` for full infrastructure documentation
