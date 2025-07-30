package service

import (
	"context"
	"fmt"

	"demo/internal/models"
	"demo/internal/repository"
)

type OrderService struct {
	orderRepo *repository.OrderRepository
}

func NewOrderService(orderRepo *repository.OrderRepository) *OrderService {
	return &OrderService{
		orderRepo: orderRepo,
	}
}

func (s *OrderService) CreateOrder(ctx context.Context, req *models.CreateOrderRequest) (*models.OrderResponse, error) {
	// Validate request
	if err := s.validateCreateOrderRequest(req); err != nil {
		return nil, err
	}

	// Calculate and verify total price
	calculatedTotal := s.calculateTotalPrice(req.Products)
	if calculatedTotal != req.TotalPrice {
		return nil, fmt.Errorf("total price mismatch: calculated %.2f, provided %.2f", calculatedTotal, req.TotalPrice)
	}

	return s.orderRepo.CreateOrder(ctx, req)
}

func (s *OrderService) GetOrderByID(ctx context.Context, orderID int) (*models.OrderResponse, error) {
	if orderID <= 0 {
		return nil, fmt.Errorf("invalid order ID")
	}

	return s.orderRepo.GetOrderByID(ctx, orderID)
}

func (s *OrderService) UpdateOrderStatus(ctx context.Context, orderID int, status string) error {
	if orderID <= 0 {
		return fmt.Errorf("invalid order ID")
	}

	if status != "processing" && status != "success" {
		return fmt.Errorf("invalid status: must be 'processing' or 'success'")
	}

	return s.orderRepo.UpdateOrderStatus(ctx, orderID, status)
}

func (s *OrderService) GetOrderStats(ctx context.Context) (map[string]interface{}, error) {
	return s.orderRepo.GetOrderStats(ctx)
}

func (s *OrderService) validateCreateOrderRequest(req *models.CreateOrderRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}

	if len(req.Products) == 0 {
		return fmt.Errorf("products cannot be empty")
	}

	if req.TotalPrice <= 0 {
		return fmt.Errorf("total price must be greater than 0")
	}

	for i, product := range req.Products {
		if product.ID <= 0 {
			return fmt.Errorf("product[%d]: ID must be greater than 0", i)
		}
		if product.Name == "" {
			return fmt.Errorf("product[%d]: name cannot be empty", i)
		}
		if product.Price <= 0 {
			return fmt.Errorf("product[%d]: price must be greater than 0", i)
		}
		if product.Quantity <= 0 {
			return fmt.Errorf("product[%d]: quantity must be greater than 0", i)
		}
	}

	return nil
}

func (s *OrderService) calculateTotalPrice(products []models.Product) float64 {
	var total float64
	for _, product := range products {
		total += product.Price * float64(product.Quantity)
	}
	return total
}
