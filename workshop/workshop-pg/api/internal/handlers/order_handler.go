package handlers

import (
	"net/http"
	"strconv"

	"demo/internal/models"
	"demo/internal/service"

	"github.com/labstack/echo/v4"
)

type OrderHandler struct {
	orderService *service.OrderService
}

func NewOrderHandler(orderService *service.OrderService) *OrderHandler {
	return &OrderHandler{
		orderService: orderService,
	}
}

// CreateOrder handles POST /order
func (h *OrderHandler) CreateOrder(c echo.Context) error {
	var req models.CreateOrderRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Message: err.Error(),
		})
	}

	order, err := h.orderService.CreateOrder(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Failed to create order",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, models.SuccessResponse{
		Message: "Order created successfully",
		Data:    order,
	})
}

// GetOrder handles GET /order/:id
func (h *OrderHandler) GetOrder(c echo.Context) error {
	idParam := c.Param("id")
	orderID, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid order ID",
			Message: "Order ID must be a valid integer",
		})
	}

	order, err := h.orderService.GetOrderByID(c.Request().Context(), orderID)
	if err != nil {
		if err.Error() == "order not found" {
			return c.JSON(http.StatusNotFound, models.ErrorResponse{
				Error:   "Order not found",
				Message: "Order with the specified ID does not exist",
			})
		}
		return c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get order",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusOK, order)
}

// UpdateOrderStatus handles PATCH /order/:id/status
func (h *OrderHandler) UpdateOrderStatus(c echo.Context) error {
	idParam := c.Param("id")
	orderID, err := strconv.Atoi(idParam)
	if err != nil {
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid order ID",
			Message: "Order ID must be a valid integer",
		})
	}

	var req struct {
		Status string `json:"status"`
	}
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid request body",
			Message: err.Error(),
		})
	}

	err = h.orderService.UpdateOrderStatus(c.Request().Context(), orderID, req.Status)
	if err != nil {
		if err.Error() == "order not found" {
			return c.JSON(http.StatusNotFound, models.ErrorResponse{
				Error:   "Order not found",
				Message: "Order with the specified ID does not exist",
			})
		}
		return c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Failed to update order status",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Order status updated successfully",
	})
}

// GetOrderStats handles GET /order/stats
func (h *OrderHandler) GetOrderStats(c echo.Context) error {
	stats, err := h.orderService.GetOrderStats(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "Failed to get order statistics",
			Message: err.Error(),
		})
	}

	return c.JSON(http.StatusOK, models.SuccessResponse{
		Message: "Order statistics retrieved successfully",
		Data:    stats,
	})
}
