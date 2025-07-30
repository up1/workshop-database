package routes

import (
	"demo/internal/handlers"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func SetupRoutes(e *echo.Echo, orderHandler *handlers.OrderHandler) {
	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	// // Request timeout middleware
	// e.Use(middleware.TimeoutWithConfig(middleware.TimeoutConfig{
	// 	Timeout: 30000, // 30 seconds
	// }))

	// Health check endpoint
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(200, map[string]string{
			"status":  "ok",
			"service": "order-api",
		})
	})

	// Order routes
	e.POST("/order", orderHandler.CreateOrder)
	e.GET("/order/:id", orderHandler.GetOrder)
	e.PATCH("/order/:id/status", orderHandler.UpdateOrderStatus)
	e.GET("/order/stats", orderHandler.GetOrderStats)

	// Database stats endpoint
	e.GET("/db/stats", func(c echo.Context) error {
		// This will be implemented in main.go to access database stats
		return c.JSON(200, map[string]string{
			"message": "Database stats endpoint",
		})
	})
}
