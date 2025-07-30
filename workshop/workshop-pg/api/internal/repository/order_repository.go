package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"demo/internal/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type OrderRepository struct {
	db *pgxpool.Pool
}

func NewOrderRepository(db *pgxpool.Pool) *OrderRepository {
	return &OrderRepository{db: db}
}

func (r *OrderRepository) CreateOrder(ctx context.Context, req *models.CreateOrderRequest) (*models.OrderResponse, error) {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Insert order
	var orderID int
	insertOrderSQL := `
		INSERT INTO orders (total_price, status)
		VALUES ($1, 'processing')
		RETURNING id
	`
	err = tx.QueryRow(ctx, insertOrderSQL, req.TotalPrice).Scan(&orderID)
	if err != nil {
		return nil, fmt.Errorf("failed to insert order: %w", err)
	}

	// Insert order items
	insertItemSQL := `
		INSERT INTO order_items (order_id, product_id, product_name, price, quantity)
		VALUES ($1, $2, $3, $4, $5)
	`
	fmt.Print("Creating order with ID:", orderID)
	for _, product := range req.Products {
		_, err = tx.Exec(ctx, insertItemSQL, orderID, product.ID, product.Name, product.Price, product.Quantity)
		if err != nil {
			return nil, fmt.Errorf("failed to insert order item: %w", err)
		}
	}

	// Commit transaction
	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	// Return the created order
	return &models.OrderResponse{
		OrderID:    orderID,
		Products:   req.Products,
		TotalPrice: req.TotalPrice,
		Status:     "processing",
	}, nil
}

func (r *OrderRepository) GetOrderByID(ctx context.Context, orderID int) (*models.OrderResponse, error) {
	// Use the pre-join summary table for optimized performance
	query := `
		SELECT order_id, total_price, status, products
		FROM order_summary
		WHERE order_id = $1
	`

	var response models.OrderResponse
	var productsJSON []byte

	err := r.db.QueryRow(ctx, query, orderID).Scan(
		&response.OrderID,
		&response.TotalPrice,
		&response.Status,
		&productsJSON,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("order not found")
		}
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	// Parse products JSON
	if err := json.Unmarshal(productsJSON, &response.Products); err != nil {
		return nil, fmt.Errorf("failed to parse products JSON: %w", err)
	}

	return &response, nil
}

func (r *OrderRepository) UpdateOrderStatus(ctx context.Context, orderID int, status string) error {
	updateSQL := `
		UPDATE orders 
		SET status = $1, updated_at = NOW()
		WHERE id = $2
	`

	result, err := r.db.Exec(ctx, updateSQL, status, orderID)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("order not found")
	}

	return nil
}

func (r *OrderRepository) GetOrderStats(ctx context.Context) (map[string]interface{}, error) {
	query := `
		SELECT 
			COUNT(*) as total_orders,
			COUNT(CASE WHEN status = 'processing' THEN 1 END) as processing_orders,
			COUNT(CASE WHEN status = 'success' THEN 1 END) as success_orders,
			COALESCE(AVG(total_price), 0) as avg_order_value
		FROM orders
	`

	var stats map[string]interface{} = make(map[string]interface{})
	var totalOrders, processingOrders, successOrders int
	var avgOrderValue float64

	err := r.db.QueryRow(ctx, query).Scan(&totalOrders, &processingOrders, &successOrders, &avgOrderValue)
	if err != nil {
		return nil, fmt.Errorf("failed to get order stats: %w", err)
	}

	stats["total_orders"] = totalOrders
	stats["processing_orders"] = processingOrders
	stats["success_orders"] = successOrders
	stats["avg_order_value"] = avgOrderValue

	return stats, nil
}
