# Workshop :: Sharding with PostgreSQL
* Sharding
  * Distributing data across multiple independent database instances (servers)
  * Shared-Nothing Architecture: Each shard is self-contained
* Why sharding ?
  * To overcome single-server limitations (CPU, RAM, Disk I/O)
* Sharding Strategies
  * Range-Based Sharding
  * Hash or key-Based Sharding
  * List/Directory-Based Sharding
  * Composite Sharding
  * Sharding Key
* PostgreSQL Sharding Approaches
  * Application-Level Sharding
  * Middleware/Proxy-Based Sharding

## 1. Application-Level Sharding for Order Data
* Shard orders data by customer_id across multiple PostgreSQL instances


### 1.1 Create 3 shards (database schema)
```
$docker compose up -d pg_shard0
$docker compose up -d pg_shard1
$docker compose up -d pg_shard2

$docker compose ps
```

### 1.2 Create table in 3 databases;
```
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    total_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    product_details JSONB, -- For demonstrating GIN/inverted index concept
    delivery_address TEXT,
    notes TEXT
);
```

### 1.3 Try with coding
* In folder `/app/`

### 1.4 Problems with Cross-shard queries
* How would you get the total orders across all customers for a specific order_date ?
* Requires fanning out queries to all shards and aggregating results in the application
* Show how a query like SELECT COUNT(*) FROM orders WHERE order_date = '2024-02-15' 
  * need to be run on each shard and then summed up by the application

### 1.5 Sharding Challenges and Considerations
* Joins across shards
* Data Rebalancing
* Shard Key Choice
* Schema Evolution
* Monitoring and Management
