# Tenant Mapper Service

A lightweight Go service that resolves custom domains to Tenant IDs for multi-tenant SaaS applications.

## Overview

The Tenant Mapper service is designed to work with Nginx Ingress Controller's `auth-url` feature. It enables routing based on custom domains by looking up tenant mappings in Redis.

## How It Works

1. Nginx Ingress receives a request on a custom domain (e.g., `customer.com`)
2. Before routing to the backend, Nginx calls the tenant-mapper service via `auth-url`
3. Tenant Mapper reads the `X-Original-Host` header
4. Queries Redis using the key pattern `domain:{host}`
5. Returns HTTP 200 with `X-Tenant-ID` header if found
6. Nginx injects the `X-Tenant-ID` header into the proxied request to the backend service

## Configuration

### Environment Variables

- `REDIS_ADDR`: Redis server address (default: `redis:6379`)
- `REDIS_PASSWORD`: Redis password (default: empty)

### Redis Key Format

The service expects Redis keys in the format:
```
domain:customer.com -> tenant-id-123
domain:acme.com -> tenant-id-456
```

## API Endpoints

### `GET /` (Any path)
Main tenant resolution endpoint. Used by Nginx auth-url.

**Request Headers:**
- `X-Original-Host`: The original host from the incoming request

**Response:**
- `200 OK`: Tenant found, includes `X-Tenant-ID` header
- `401 Unauthorized`: No tenant mapping found for the domain
- `500 Internal Server Error`: Redis connection error

### `GET /health`
Health check endpoint.

**Response:**
- `200 OK`: Service is running

### `GET /ready`
Readiness probe endpoint.

**Response:**
- `200 OK`: Service is ready and Redis is accessible
- `503 Service Unavailable`: Redis is not accessible

## Building

```bash
go build -o tenant-mapper main.go
```

## Running

```bash
# Set environment variables
export REDIS_ADDR=localhost:6379
export REDIS_PASSWORD=your-password

# Run the service
./tenant-mapper
```

## Docker

Build the Docker image:
```bash
docker build -t tenant-mapper:latest .
```

Run with Docker:
```bash
docker run -p 80:80 \
  -e REDIS_ADDR=redis:6379 \
  -e REDIS_PASSWORD=your-password \
  tenant-mapper:latest
```

## Testing

To test the service, you can populate Redis with test data:

```bash
redis-cli SET domain:customer.com tenant-123
redis-cli SET domain:acme.com tenant-456
```

Then make a request:
```bash
curl -H "X-Original-Host: customer.com" http://localhost:80
```

## Kubernetes Deployment

The service is deployed as part of the infrastructure and is used by Nginx Ingress for Pattern B routing (custom domains).

See `kubernetes/base/services/tenant-mapper/` for deployment manifests.
