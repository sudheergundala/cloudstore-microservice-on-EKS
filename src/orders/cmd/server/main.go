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

	"github.com/cloudstore/order-service/internal/handler"
	"github.com/cloudstore/order-service/internal/repository"
	"github.com/gorilla/mux"
)

func main() {
	// Configuration from environment variables
	port := getEnv("PORT", "8081")
	dbURL := getEnv("DATABASE_URL", "postgres://cloudstore:secret123@localhost:5432/orders?sslmode=disable")
	productCatalogURL := getEnv("PRODUCT_CATALOG_URL", "http://localhost:8000")

	// Connect to PostgreSQL
	repo, err := repository.NewPostgresRepo(dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer repo.Close()
	log.Println("Connected to PostgreSQL")

	// Set up routes
	r := mux.NewRouter()
	orderHandler := handler.NewOrderHandler(repo, productCatalogURL)

	// Health endpoints
	r.HandleFunc("/health", handler.HealthCheck).Methods("GET")
	r.HandleFunc("/ready", handler.ReadinessCheck(repo)).Methods("GET")

	// Order endpoints
	r.HandleFunc("/orders", orderHandler.CreateOrder).Methods("POST")
	r.HandleFunc("/orders/{id}", orderHandler.GetOrder).Methods("GET")
	r.HandleFunc("/orders", orderHandler.ListOrders).Methods("GET")

	// Create HTTP server
	server := &http.Server{
		Addr:         fmt.Sprintf("0.0.0.0:%s", port),
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Order service starting on 0.0.0.0:%s", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGTERM, syscall.SIGINT)
	sig := <-quit
	log.Printf("Received %v signal. Shutting down gracefully...", sig)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped cleanly")
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
