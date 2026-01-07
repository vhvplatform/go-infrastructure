package middleware

import (
	"context"
	"net/http"

	"github.com/labstack/echo/v4"
)

// TenancyMiddlewareEcho is the Echo framework version of the tenancy middleware
// Extracts X-Tenant-ID header and validates tenant isolation
// Returns 400 Bad Request if X-Tenant-ID header is missing
func TenancyMiddlewareEcho() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Extract X-Tenant-ID header
			tenantID := c.Request().Header.Get(TenantIDHeader)
			
			// Validate tenant ID is present
			if tenantID == "" {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"error":   "Missing tenant identifier",
					"message": "X-Tenant-ID header is required for all tenant operations",
					"code":    "TENANT_ID_REQUIRED",
				})
			}
			
			// Validate tenant ID format (basic validation)
			if len(tenantID) < 3 || len(tenantID) > 128 {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"error":   "Invalid tenant identifier",
					"message": "X-Tenant-ID must be between 3 and 128 characters",
					"code":    "INVALID_TENANT_ID",
				})
			}
			
			// Store tenant ID in Echo context
			c.Set(string(TenantIDKey), tenantID)
			
			// Store in request context for use in non-Echo code
			ctx := context.WithValue(c.Request().Context(), TenantIDKey, tenantID)
			c.SetRequest(c.Request().WithContext(ctx))
			
			// Continue to next handler
			return next(c)
		}
	}
}

// GetTenantIDEcho retrieves the tenant ID from Echo context
// Returns empty string if tenant ID is not found
func GetTenantIDEcho(c echo.Context) string {
	if tenantID := c.Get(string(TenantIDKey)); tenantID != nil {
		if tid, ok := tenantID.(string); ok {
			return tid
		}
	}
	return ""
}

// MustGetTenantIDEcho retrieves tenant ID from Echo context and panics if not found
// Use this in handlers where tenant ID is guaranteed to exist due to middleware
func MustGetTenantIDEcho(c echo.Context) string {
	tenantID := GetTenantIDEcho(c)
	if tenantID == "" {
		panic("tenant ID not found in context - ensure TenancyMiddlewareEcho is applied")
	}
	return tenantID
}

// Example Usage in Echo Route Handler:
//
// func GetUserHandler(c echo.Context) error {
//     tenantID := middleware.MustGetTenantIDEcho(c)
//     userID := c.Param("id")
//     
//     // Query with tenant isolation
//     user, err := userRepo.FindByID(c.Request().Context(), tenantID, userID)
//     if err != nil {
//         return c.JSON(http.StatusNotFound, map[string]string{"error": "User not found"})
//     }
//     
//     return c.JSON(http.StatusOK, user)
// }
//
// Example Usage in Echo Router Setup:
//
// func SetupEchoRouter() *echo.Echo {
//     e := echo.New()
//     
//     // Public routes (no tenant required)
//     e.GET("/health", HealthHandler)
//     e.POST("/login", LoginHandler)
//     
//     // Tenant-aware routes
//     tenantRoutes := e.Group("/api")
//     tenantRoutes.Use(middleware.TenancyMiddlewareEcho())
//     tenantRoutes.GET("/users/:id", GetUserHandler)
//     tenantRoutes.POST("/users", CreateUserHandler)
//     tenantRoutes.GET("/orders", ListOrdersHandler)
//     
//     return e
// }
