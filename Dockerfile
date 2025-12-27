# =============================================================================
# Production Dockerfile
# =============================================================================
# Multi-stage build optimized for:
# - Minimal image size
# - Security (non-root user, distroless base)
# - Production performance
# =============================================================================

# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Copy and download dependencies (cached layer)
COPY services/tenant-mapper/go.mod services/tenant-mapper/go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY services/tenant-mapper/ ./

# Build with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o tenant-mapper \
    main.go

# Runtime stage - using distroless for security
FROM gcr.io/distroless/static-debian12:nonroot

# Copy timezone data and CA certificates from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binary
COPY --from=builder /app/tenant-mapper /tenant-mapper

# Use non-root user
USER nonroot:nonroot

# Expose port
EXPOSE 80

# Run the application
ENTRYPOINT ["/tenant-mapper"]
