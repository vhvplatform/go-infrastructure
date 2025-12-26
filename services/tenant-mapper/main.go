package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	redisClient *redis.Client
	ctx         = context.Background()
)

func main() {
	// Initialize Redis client
	redisAddr := getEnv("REDIS_ADDR", "redis:6379")
	redisPassword := getEnv("REDIS_PASSWORD", "")
	redisDB := 0

	redisClient = redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
		DB:       redisDB,
	})

	// Test Redis connection
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Printf("Warning: Unable to connect to Redis: %v", err)
	} else {
		log.Println("Successfully connected to Redis")
	}

	// Set up HTTP server
	mux := http.NewServeMux()
	mux.HandleFunc("/", tenantMapperHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/ready", readyHandler)

	server := &http.Server{
		Addr:         ":80",
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  15 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Println("Tenant Mapper service listening on :80")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	redisClient.Close()
	log.Println("Server exited")
}

// tenantMapperHandler resolves domain to tenant ID
func tenantMapperHandler(w http.ResponseWriter, r *http.Request) {
	// Get the original host from the X-Original-Host header
	// This is set by nginx ingress when using auth-url
	originalHost := r.Header.Get("X-Original-Host")
	if originalHost == "" {
		// Fallback to X-Forwarded-Host if X-Original-Host is not set
		originalHost = r.Header.Get("X-Forwarded-Host")
	}
	if originalHost == "" {
		// Last fallback to Host header
		originalHost = r.Host
	}

	if originalHost == "" {
		log.Printf("No host header found in request")
		http.Error(w, "No host header found", http.StatusBadRequest)
		return
	}

	log.Printf("Resolving tenant for domain: %s", originalHost)

	// Query Redis for tenant ID using the pattern domain:{host}
	redisKey := fmt.Sprintf("domain:%s", originalHost)
	tenantID, err := redisClient.Get(ctx, redisKey).Result()

	if err == redis.Nil {
		log.Printf("No tenant mapping found for domain: %s", originalHost)
		http.Error(w, "Tenant not found for domain", http.StatusUnauthorized)
		return
	} else if err != nil {
		log.Printf("Redis error for domain %s: %v", originalHost, err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Set the X-Tenant-ID header in the response
	// Nginx will copy this header to the proxied request
	w.Header().Set("X-Tenant-ID", tenantID)
	
	log.Printf("Resolved domain %s to tenant: %s", originalHost, tenantID)
	
	// Return 200 OK
	w.WriteHeader(http.StatusOK)
}

// healthHandler provides a health check endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// readyHandler checks if the service is ready (Redis connection is up)
func readyHandler(w http.ResponseWriter, r *http.Request) {
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Printf("Readiness check failed: Redis is not available: %v", err)
		http.Error(w, "Service not ready", http.StatusServiceUnavailable)
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Ready"))
}

// getEnv retrieves environment variable or returns default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
