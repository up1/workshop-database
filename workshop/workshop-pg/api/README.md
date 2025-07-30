# Order Management REST API

A high-performance REST API built with Go, Echo framework, and PostgreSQL using pgx driver for managing orders and order items.

## Features

- **High Performance**: Optimized PostgreSQL connection pooling with pgx driver
- **Pre-join Optimization**: Uses pre-computed summary table for fast order retrieval
- **Transaction Safety**: Atomic order creation with proper rollback handling
- **Graceful Shutdown**: Proper cleanup of database connections and server shutdown
- **Health Checks**: Built-in health and database statistics endpoints

## Architecture

- **Echo Framework**: Fast HTTP router and middleware
- **pgx Driver**: High-performance PostgreSQL driver with connection pooling
- **Layered Architecture**: Clean separation of concerns (handlers → services → repositories)
- **Database Triggers**: Automatic summary table updates for optimized reads

## API Endpoints

### Create Order
```
POST /order
Content-Type: application/json

{
  "products": [
    {
      "id": 1,
      "name": "Product A",
      "price": 100.50,
      "quantity": 2
    }
  ],
  "total_price": 201.00
}
```

### Get Order by ID
```
GET /order/:id

Response:
{
  "order_id": 123,
  "products": [
    {
      "id": 1,
      "name": "Product A", 
      "price": 100.50,
      "quantity": 2
    }
  ],
  "total_price": 201.00,
  "status": "processing"
}
```

### Update Order Status
```
PATCH /order/:id/status
Content-Type: application/json

{
  "status": "success"
}
```

### Health Check
```
GET /health
```

### Database Statistics
```
GET /db/stats
```

### Order Statistics
```
GET /order/stats
```

## Database Schema

### Tables
- `orders`: Main order information
- `order_items`: Individual products in each order
- `order_summary`: Pre-join table for optimized order retrieval

### Performance Optimizations
- Connection pooling with tuned parameters
- Database indexes on frequently queried columns
- Pre-computed summary table with triggers
- Optimized queries using prepared statements

## Setup Instructions

1. **Install Dependencies**
   ```bash
   go mod tidy
   ```

2. **Setup Database**
   ```bash
   # Create database
   createdb workshop_db
   
   # Run migrations
   psql -d workshop_db -f migrations/001_init.sql
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Run the Application**
   ```bash
   go run main.go
   ```

## Performance Tuning

The application includes optimized connection pool settings:

- **MaxConns**: 25 (maximum concurrent connections)
- **MinConns**: 5 (minimum idle connections) 
- **MaxConnLifetime**: 1 hour (connection recycling)
- **MaxConnIdleTime**: 30 minutes (idle connection cleanup)

These settings can be adjusted via environment variables for your specific workload.

## Project Structure

```
api/
├── main.go
├── go.mod
├── .env.example
├── migrations/
│   └── 001_init.sql
└── internal/
    ├── config/
    │   └── config.go
    ├── database/
    │   └── connection.go
    ├── models/
    │   └── order.go
    ├── repository/
    │   └── order_repository.go
    ├── service/
    │   └── order_service.go
    ├── handlers/
    │   └── order_handler.go
    └── routes/
        └── routes.go
```
