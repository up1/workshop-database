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

	"demo/internal/config"
	"demo/internal/database"
	"demo/internal/handlers"
	"demo/internal/repository"
	"demo/internal/routes"
	"demo/internal/service"

	"github.com/labstack/echo/v4"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Connect to database
	db, err := database.NewConnection(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize layers
	orderRepo := repository.NewOrderRepository(db.Pool)
	orderService := service.NewOrderService(orderRepo)
	orderHandler := handlers.NewOrderHandler(orderService)

	// Initialize Echo
	e := echo.New()

	// Setup routes
	routes.SetupRoutes(e, orderHandler)

	// Add database stats endpoint
	e.GET("/db/stats", func(c echo.Context) error {
		stats := db.GetStats()
		return c.JSON(http.StatusOK, map[string]interface{}{
			"total_conns":                stats.TotalConns(),
			"acquired_conns":             stats.AcquiredConns(),
			"idle_conns":                 stats.IdleConns(),
			"max_conns":                  stats.MaxConns(),
			"acquire_count":              stats.AcquireCount(),
			"acquire_duration":           stats.AcquireDuration().String(),
			"constructing_conns":         stats.ConstructingConns(),
			"empty_acquire_count":        stats.EmptyAcquireCount(),
			"max_lifetime_destroy_count": stats.MaxLifetimeDestroyCount(),
			"max_idle_destroy_count":     stats.MaxIdleDestroyCount(),
		})
	})

	// Start server with graceful shutdown
	go func() {
		address := fmt.Sprintf(":%s", cfg.Port)
		log.Printf("Server starting on port %s", cfg.Port)
		log.Printf("Database pool configuration: MaxConns=%d, MinConns=%d", cfg.MaxConns, cfg.MinConns)

		if err := e.Start(address); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Give outstanding requests a deadline for completion
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
