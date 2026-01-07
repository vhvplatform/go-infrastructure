# Server - Backend Microservices

This directory contains Golang-based backend microservices for the platform.

## Structure

```
server/
├── middleware/          # Go tenancy middleware (Gin/Echo)
├── tenant-mapper/       # Domain to tenant ID resolution service
└── service-name-n/      # Additional backend services
```

## Existing Services

### Middleware
Go middleware for multi-tenant applications supporting both Gin and Echo frameworks.
See [middleware/README.md](middleware/README.md) for details.

### Tenant Mapper
Domain resolution service that maps custom domains to tenant IDs using Redis.
See [tenant-mapper/README.md](tenant-mapper/README.md) for details.

## Getting Started

Each backend microservice is a Go module with:
- `go.mod` - Go module dependencies
- `main.go` - Service entry point
- `README.md` - Service-specific documentation

## Development

```bash
cd server/service-name
go mod download
go run main.go
```

## Build

```bash
go build -o service-name
```

## Testing

```bash
go test -v ./...
```

## Docker

```bash
docker build -t service-name .
docker run -p 8080:80 service-name
```
