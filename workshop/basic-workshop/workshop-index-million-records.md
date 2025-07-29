# PostgreSQL Index Workshop: Scaling with Millions of Order Records
* PostgreSQL index types 
  * B-tree index
  * Inverted Index (GIN and GiST)
  * Bitmap Index

## 1. Generate data for testing

### 1.1 Create tables
```
-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS orders;

-- Create the orders table
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
### 1.2 Create data for testing
```
-- Function to generate random data
CREATE OR REPLACE FUNCTION generate_random_orders(num_rows INT) RETURNS VOID AS $$
DECLARE
    i INT;
    random_customer_id INT;
    random_total_amount NUMERIC(10, 2);
    random_status TEXT;
    random_product_details JSONB;
    random_date TIMESTAMP;
    statuses TEXT[] := ARRAY['Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned'];
BEGIN
    FOR i IN 1..num_rows LOOP
        random_customer_id := floor(random() * 1000000) + 1; -- 1 to 1M customers
        random_total_amount := round((random() * 10000)::NUMERIC, 2); -- 0 to 10000
        random_status := statuses[floor(random() * array_length(statuses, 1)) + 1];
        random_date := NOW() - (random() * INTERVAL '5 years');

        -- Generate some varied product details for JSONB
        random_product_details := jsonb_build_object(
            'item_count', floor(random() * 10) + 1,
            'main_category', CASE floor(random()*3) WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Books' ELSE 'Apparel' END,
            'has_discount', (random() > 0.5)
        );

        INSERT INTO orders (customer_id, order_date, total_amount, status, product_details, delivery_address, notes)
        VALUES (
            random_customer_id,
            random_date,
            random_total_amount,
            random_status,
            random_product_details,
            'Address ' || i || ', City ' || (floor(random()*100)+1) || ', Zip ' || (floor(random()*90000)+10000),
            'Note ' || i || ' for order ' || random_customer_id
        );

        IF i % 100000 = 0 THEN
            RAISE NOTICE 'Inserted % rows', i;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Populate with 5 million records (adjust as needed for your system's capacity)
SELECT generate_random_orders(5000000);

-- Analyze the table after data insertion
ANALYZE orders;

-- Check record count
SELECT COUNT(*) FROM orders;
```

## 2. Working with B-tree index
* Cardinality: Most effective on columns with high cardinality (many unique values)
* Selectivity: Queries that retrieve a small percentage of rows will benefit most
* Index Bloat: Frequent updates/deletes can lead to bloat
  * VACUUM FULL (offline) or REINDEX (online with lock) can reclaim space
  * Autovacuum helps
* Maintenance Overhead: Each insert/update/delete on an indexed column requires index modification
  * More indexes = more write overhead

### 2.1 Start with no-index !!
```
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 500000;

EXPLAIN ANALYZE SELECT * FROM orders WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';

EXPLAIN ANALYZE SELECT * FROM orders WHERE total_amount > 5000 ORDER BY total_amount DESC LIMIT 100;

EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 123456 AND status = 'Delivered';
```

### 2.2 Create B-tree index
```
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_order_date ON orders (order_date);
CREATE INDEX idx_orders_total_amount ON orders (total_amount);

-- Composite index for multiple columns (useful for queries filtering on both)
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);


ANALYZE orders;
```

### 2.3 Query with index
```
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 500000;

EXPLAIN ANALYZE SELECT * FROM orders WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';

EXPLAIN ANALYZE SELECT * FROM orders WHERE total_amount > 5000 ORDER BY total_amount DESC LIMIT 100;

EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 123456 AND status = 'Delivered';
```

### 2.4 Covering Index
* Explain the benefit of Index Only Scan where the query can be fully satisfied by the index without touching the table.
```
CREATE INDEX idx_orders_customer_id_covered ON orders (customer_id) INCLUDE (total_amount, status);

EXPLAIN ANALYZE SELECT customer_id, total_amount, status FROM orders WHERE customer_id = 500000;
```

## 3. Inverted Index (GIN and GiST for PostgreSQL)
* GIN (Generalized Inverted Index) 
  * Ideal for indexing JSONB, arrays, and full-text search (tsvector)
* GiST (Generalized Search Tree)
  * More general-purpose tree structure, suitable for geometric data, full-text search, and specific operators (e.g., k-nearest neighbor)
* Indexing complex data types where a single value can have multiple searchable components

### 3.1 Working with GIN
* Space Usage: GIN indexes can be very large because they index every element
* Write Performance: GIN indexes can be slower to update/insert due to their complexity
* Specific Operators: Ensure your queries use operators that the GIN/GiST index can utilize (e.g., @>, ?, @@ for tsvector)

No Index on JSONB
```
EXPLAIN ANALYZE SELECT * FROM orders WHERE product_details ->> 'main_category' = 'Electronics';

EXPLAIN ANALYZE SELECT * FROM orders WHERE product_details @> '{"has_discount": true}';
```

Create GIN Index on JSONB
* Observe Bitmap Index Scan or Index Scan
```
-- For ->> (contains operator)
CREATE INDEX idx_orders_main_category ON orders ((product_details ->> 'main_category'));

-- For specific key-value lookups (JSONB operations like ->>)
-- This requires a specific operator class or expression index for efficient use.
-- For example, to index the 'main_category' key:
CREATE INDEX idx_orders_product_details_main_category_gin ON orders USING GIN ((to_tsvector('english', product_details->>'main_category')));
```

## 4. Bitmap Index
* PostgreSQL does not have a direct "Bitmap Index" type
* Bitmap Heap Scans or Bitmap Index Scans which are an execution plan type

### 4.1 Try to create index for low-cardinality column
* Index Scan or Bitmap Heap Scan depending on data distribution and selectivity

```
-- Status is a low-cardinality column
CREATE INDEX idx_orders_status_btree ON orders (status);

EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'Pending';
```

### 4.2 Combine Indexes to trigger Bitmap Heap Scan
```
-- Ensure indexes exist
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_order_date ON orders (order_date);

EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'Pending' AND customer_id BETWEEN 100000 AND 200000;

EXPLAIN ANALYZE SELECT * FROM orders WHERE status = 'Shipped' AND order_date > '2024-06-01';
```

## Workshop Conclusion & General Tuning Principles
* EXPLAIN ANALYZE is your best friend
  * Always use it to understand how your queries are executing and if indexes are being used
* Cardinality & Selectivity
  * High cardinality (many unique values): B-tree is usually excellent for direct lookups and range scans
  * Low cardinality (few unique values): B-tree can still be useful, but Bitmap Heap Scan might be preferred by the planner when combined with other conditions
* Write Overhead vs. Read Performance
  * Indexes speed up reads but slow down writes (INSERT, UPDATE, DELETE)
  * Balance this trade-off
  * Don't index every column
* Disk Space : Indexes consume disk space
* Maintenance: Indexes need to be maintained during DML operations
  * Autovacuum is crucial
  * REINDEX can help with bloat
* Partial Indexes: Index only a subset of rows 
  * e.g., CREATE INDEX ON orders (customer_id) WHERE status = 'Pending';
* Monitoring: Monitor database performance 
  * e.g., pg_stat_statements, pg_buffercache 
    * to identify slow queries and underutilized indexes