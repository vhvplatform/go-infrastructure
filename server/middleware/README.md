# Go Tenancy Middleware

Multi-framework Go middleware for enforcing tenant isolation in multi-tenant SaaS applications.

## Overview

This package provides tenant context management middleware for both **Gin** and **Echo** web frameworks. It extracts the `X-Tenant-ID` header from incoming requests, validates it, and makes it available throughout the request lifecycle.

## Features

- ✅ Support for Gin and Echo frameworks
- ✅ Automatic `X-Tenant-ID` header extraction
- ✅ Validation of tenant ID format
- ✅ Context propagation for tenant isolation
- ✅ Type-safe tenant ID retrieval
- ✅ Audit logging support
- ✅ Comprehensive error responses

## Installation

```bash
go get github.com/vhvplatform/go-infrastructure/server/middleware
```

## Usage

### Gin Framework

```go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/vhvplatform/go-infrastructure/server/middleware"
)

func main() {
    r := gin.Default()
    
    // Public routes (no tenant required)
    r.GET("/health", HealthHandler)
    r.POST("/login", LoginHandler)
    
    // Tenant-aware routes
    tenantRoutes := r.Group("/api")
    tenantRoutes.Use(middleware.TenancyMiddleware())
    {
        tenantRoutes.GET("/users/:id", GetUserHandler)
        tenantRoutes.POST("/users", CreateUserHandler)
    }
    
    r.Run(":8080")
}

func GetUserHandler(c *gin.Context) {
    // Get tenant ID from context
    tenantID := middleware.MustGetTenantID(c)
    userID := c.Param("id")
    
    // Query with tenant isolation
    user, err := db.FindUser(c.Request.Context(), tenantID, userID)
    if err != nil {
        c.JSON(404, gin.H{"error": "User not found"})
        return
    }
    
    c.JSON(200, user)
}
```

### Echo Framework

```go
package main

import (
    "github.com/labstack/echo/v4"
    "github.com/vhvplatform/go-infrastructure/server/middleware"
)

func main() {
    e := echo.New()
    
    // Public routes
    e.GET("/health", HealthHandler)
    
    // Tenant-aware routes
    api := e.Group("/api")
    api.Use(middleware.TenancyMiddlewareEcho())
    api.GET("/users/:id", GetUserHandler)
    
    e.Start(":8080")
}

func GetUserHandler(c echo.Context) error {
    tenantID := middleware.MustGetTenantIDEcho(c)
    userID := c.Param("id")
    
    user, err := db.FindUser(c.Request().Context(), tenantID, userID)
    if err != nil {
        return c.JSON(404, map[string]string{"error": "User not found"})
    }
    
    return c.JSON(200, user)
}
```

## Database Integration

Always include tenant ID in database queries:

```go
// MongoDB Example
filter := bson.M{
    "tenant_id": tenantID,
    "_id":       userID,
}
user, err := collection.FindOne(ctx, filter)

// SQL Example
query := "SELECT * FROM users WHERE tenant_id = $1 AND id = $2"
row := db.QueryRowContext(ctx, query, tenantID, userID)
```

## API Behavior

### Success Response

When `X-Tenant-ID` header is present and valid:
- Status: `200 OK`
- Tenant ID is available in context
- Request proceeds normally

### Error Responses

**Missing Header:**
```json
{
  "error": "Missing tenant identifier",
  "message": "X-Tenant-ID header is required for all tenant operations",
  "code": "TENANT_ID_REQUIRED"
}
```
Status: `400 Bad Request`

**Invalid Format:**
```json
{
  "error": "Invalid tenant identifier",
  "message": "X-Tenant-ID must be between 3 and 128 characters",
  "code": "INVALID_TENANT_ID"
}
```
Status: `400 Bad Request`

## Helper Functions

### Gin

- `TenancyMiddleware()` - Gin middleware function
- `GetTenantID(c *gin.Context)` - Safe retrieval (returns empty string if not found)
- `MustGetTenantID(c *gin.Context)` - Panics if not found (use after middleware)
- `GetTenantIDFromContext(ctx context.Context)` - Retrieve from standard context

### Echo

- `TenancyMiddlewareEcho()` - Echo middleware function
- `GetTenantIDEcho(c echo.Context)` - Safe retrieval
- `MustGetTenantIDEcho(c echo.Context)` - Panics if not found

## Testing

```go
func TestTenancyMiddleware(t *testing.T) {
    router := gin.Default()
    router.Use(middleware.TenancyMiddleware())
    router.GET("/test", func(c *gin.Context) {
        tenantID := middleware.GetTenantID(c)
        c.JSON(200, gin.H{"tenant_id": tenantID})
    })
    
    // Test with valid tenant ID
    req := httptest.NewRequest("GET", "/test", nil)
    req.Header.Set("X-Tenant-ID", "tenant-123")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, 200, w.Code)
    
    // Test without tenant ID
    req = httptest.NewRequest("GET", "/test", nil)
    w = httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, 400, w.Code)
}
```

## Integration with Nginx Ingress

This middleware works seamlessly with the Nginx Ingress tenant routing patterns:

**Pattern A (Subfolder):** Nginx extracts tenant ID and injects header
**Pattern B (Custom Domain):** Tenant-mapper service resolves domain and injects header

Both patterns result in `X-Tenant-ID` header being present, which this middleware validates and propagates.

## Best Practices

1. **Always use tenant ID in queries**: Never query without tenant filter
2. **Apply middleware to all tenant routes**: Use route groups
3. **Use MustGet in handlers**: Since middleware guarantees presence
4. **Log tenant ID**: For audit trails and debugging
5. **Validate at boundary**: Middleware is the entry point for tenant context

## Security Considerations

- Middleware validates tenant ID format
- Tenant ID is immutable once set in context
- Each request is isolated by tenant
- No cross-tenant data leakage possible
- Compatible with network policies and RBAC

## License

See repository LICENSE file.
