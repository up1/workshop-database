# Scenario: Orders Table with Frequent Access to Recent Data (Large data)
* Order data in e-commerce system
* Analytical queries or operational tasks focus on orders from the last few weeks or months

## 1. Create table orders with [partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
* `PARTITION BY RANGE` with column=`created_at`

```
CREATE TABLE orders (
    order_id BIGSERIAL,
    customer_id INTEGER NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
) PARTITION BY RANGE (created_at);

-- Add a primary key. In a partitioned table, the primary key must include the partition key.
ALTER TABLE orders ADD PRIMARY KEY (order_id, created_at);

-- Create an index on customer_id for common lookups
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Optional: Add an index on status if you frequently filter by it
CREATE INDEX idx_orders_status ON orders (status);
```

## 2. Create partitions
```
CREATE TABLE orders_2025_01 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2025-02-01 00:00:00');

CREATE TABLE orders_2025_02 PARTITION OF orders
    FOR VALUES FROM ('2025-02-01 00:00:00') TO ('2025-03-01 00:00:00');

CREATE TABLE orders_2025_03 PARTITION OF orders
    FOR VALUES FROM ('2025-03-01 00:00:00') TO ('2025-04-01 00:00:00');

CREATE TABLE orders_2025_04 PARTITION OF orders
    FOR VALUES FROM ('2025-04-01 00:00:00') TO ('2025-05-01 00:00:00');

CREATE TABLE orders_2025_05 PARTITION OF orders
    FOR VALUES FROM ('2025-05-01 00:00:00') TO ('2025-06-01 00:00:00');

CREATE TABLE orders_2025_06 PARTITION OF orders
    FOR VALUES FROM ('2025-06-01 00:00:00') TO ('2025-07-01 00:00:00');

CREATE TABLE orders_2025_07 PARTITION OF orders
    FOR VALUES FROM ('2025-07-01 00:00:00') TO ('2025-08-01 00:00:00');

CREATE TABLE orders_2025_08 PARTITION OF orders
    FOR VALUES FROM ('2025-08-01 00:00:00') TO ('2025-09-01 00:00:00');
```

List all partitions
```
SELECT
    relnamespace::regnamespace AS schema_name,
    relname AS partition_name
FROM
    pg_class
WHERE
    relispartition AND relname LIKE 'order_%';
```

## 3. Generate Test Data for orders Table (1 Million Records)
```
INSERT INTO orders (customer_id, order_total, status, created_at)
SELECT
    -- Generate customer_id (1 to 100,000)
        (random() * 99999 + 1)::INTEGER AS customer_id,
        -- Generate order_total (10.00 to 1000.00)
        ROUND((random() * 990 + 10)::NUMERIC, 2) AS order_total,
        -- Generate status
        CASE FLOOR(random() * 5)
            WHEN 0 THEN 'pending'
            WHEN 1 THEN 'completed'
            WHEN 2 THEN 'shipped'
            WHEN 3 THEN 'cancelled'
            ELSE 'refunded'
        END AS status,
        -- Generate created_at between 2025/01 to 2025/08
        timestamp '2025-01-01 00:00:00' +
        random() * (timestamp '2025-08-31 23:59:59' - 
                    timestamp '2025-01-01 00:00:00')
        AS created_at
FROM
    generate_series(1, 1000000);
```

Check data from table orders
```
ANALYZE orders;

SELECT count(*) FROM orders;
```

## 4. Size of Indexs of table=orders
```
SELECT 
    t.tablename,
    i.indexrelname,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    pg_get_indexdef(i.indexrelid) AS index_definition,
    am.amname AS index_type
FROM pg_stat_user_indexes i
JOIN pg_tables t ON i.relname = t.tablename
JOIN pg_class c ON i.indexrelid = c.oid
JOIN pg_am am ON c.relam = am.oid
WHERE t.tablename like 'orders%'
ORDER BY pg_relation_size(i.indexrelid) DESC;
```

## 5. Analyze sql query !!

### Query data from single partition
```
EXPLAIN ANALYZE SELECT * FROM orders
WHERE created_at BETWEEN '2025-06-01 00:00:00' AND '2025-06-30 23:59:59'
AND customer_id = 12345;
```

### Query data from multiple partitions
```
EXPLAIN ANALYZE SELECT * FROM orders
WHERE created_at BETWEEN '2025-05-01 00:00:00' AND '2025-07-31 23:59:59'
AND customer_id = 12345;
```


### Try to tuning !!!
```
EXPLAIN ANALYZE SELECT customer_id, SUM(order_total) FROM orders
WHERE created_at BETWEEN '2025-06-01 00:00:00' AND '2025-06-30 23:59:59'
GROUP BY customer_id
HAVING SUM(order_total) > 1000;

EXPLAIN ANALYZE SELECT customer_id, SUM(order_total) FROM orders
WHERE created_at BETWEEN '2025-05-01 00:00:00' AND '2025-07-31 23:59:59'
GROUP BY customer_id
HAVING SUM(order_total) > 1000;
```

## 6. Monitor Autovacuum Activity per Partition
* `Dead tuples` are rows that have been deleted or updated but haven't been physically removed from the table yet
* `Autovacuum` is PostgreSQL's background process that automatically cleans up dead tuples, updates table statistics, and prevents transaction ID wraparound

```
-- Get size of partitions
SELECT 
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_table_size(relid)) as table_size,
    pg_size_pretty(pg_indexes_size(relid)) as index_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_table_size(relid)) as external_size
FROM pg_catalog.pg_statio_user_tables 
WHERE relname LIKE 'orders%'
ORDER BY pg_total_relation_size(relid) DESC;

-- Monitor Autovacuum Activity per Partition
SELECT
    schemaname,
    relname,
    pg_size_pretty(pg_table_size(relid)) as table_size,
    pg_size_pretty(pg_indexes_size(relid)) as index_size,
    n_live_tup,
    n_dead_tup,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE relname like 'orders%'
ORDER BY n_dead_tup DESC;
```

## 7. Try to delete data
```
DELETE FROM orders WHERE created_at BETWEEN '2025-05-01 00:00:00' AND '2025-05-15 23:59:59';
```

Analyze and Vacuum
```
VACUUM orders;

ANALYZE orders
```

## 8. Purge all data from partition
```
# 1. Detach partition
ALTER TABLE orders DETACH PARTITION orders_2025_01;

# 2. Backup data process

# 3. Drop partition table
DROP TABLE orders_2025_01;
```

## 9. Configure Autovacuum for the Partitioned Table
* For a high-volume table with frequent updates/inserts, we want autovacuum to be more aggressive

```
-- Apply autovacuum settings to the partitioned table
ALTER TABLE orders_2025_01 SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- Trigger VACUUM when 5% of tuples are dead
    autovacuum_analyze_scale_factor = 0.02, -- Trigger ANALYZE when 2% of tuples are changed
    autovacuum_vacuum_threshold = 1000,     -- Minimum 1000 dead tuples to trigger VACUUM
    autovacuum_analyze_threshold = 500,     -- Minimum 500 changed tuples to trigger ANALYZE
    autovacuum_vacuum_cost_delay = 5,       -- Reduce delay to make vacuuming faster (default is 10ms)
    autovacuum_vacuum_cost_limit = 1000     -- Allow more work per vacuum run (default is 200)
);
```

Try to delete data !!

