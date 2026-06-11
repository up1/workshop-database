# Workshop :: Database design with PostgreSQL

## Topics
* Database design
* Normalization vs Denormalization
* PostgreSQL features for database design
* Indexing strategies
* Query optimization
* Best practices for database design

## Use cases
* Slow query performance and how to optimize it
* Connection pooling issues and how to resolve them and scale the database
* Data caching to reduce database load and improve performance
* Separate read and write operations for better performance
* Database partitioning for large datasets

## Start Database with Docker
```bash
$docker compose up -d
$docker compose ps
```

Access to database
* password=pass

```bash
$docker compose exec db psql -U user -d orders
```

List of commands
* \l : list databases
* \c : connect to database
* \dt : list tables
* \d : describe table
* \q : quit

## Case 1: Order listing page
* List new orders by current date, sorted by created_at desc, with pagination
* Orders table has 10K–1M new orders per day, with total > 100M rows
* Query must return results in <100ms at any page depth

## Case 2: Table partitioning for large datasets
* Orders table has >100M rows, growing by 10K–1M new orders per day
* Query patterns:
  * List new orders by current date, sorted by created_at desc, with pagination
  * List orders by customer_id, sorted by created_at desc, with pagination
* Design partitioning strategy to optimize query performance for these patterns
* Implement partitioning and compare query performance before and after
