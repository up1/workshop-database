# Database design workshop
* RDBMS with PostgreSQL
    * Normalization vs De-normalization
    * Materialized Views
    * Partitioning
    * Sharding
    * Data Housekeeping

## 0. Start PostgreSQL database
```
$docker compose up -d
$docker compose ps
```

Access to pgAdmin 
* http://localhost:8080/
  * user=admin@example.com
  * password=admin
* Add new server
  * name=Demo01, 
  * host=db
  * port=5432
  * user=postgres
  * password=postgres

## 1. Normalization vs De-normalization
* Understand 3NF modeling
* When denormalization helps (reporting, read-heavy workloads)
* Trade-offs: joins & consistency vs. write amplification & storage


### 1.1 Normalization
```
-- Customers, Products, Orders, Order Items, Payments
CREATE TABLE norm.customers (
  customer_id  BIGSERIAL PRIMARY KEY,
  full_name    TEXT NOT NULL,
  email        TEXT UNIQUE NOT NULL,
  region       TEXT CHECK (region IN ('NORTH','SOUTH','EAST','WEST'))
);

CREATE TABLE norm.products (
  product_id   BIGSERIAL PRIMARY KEY,
  sku          TEXT UNIQUE NOT NULL,
  name         TEXT NOT NULL,
  unit_price   NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE norm.orders (
  order_id     BIGSERIAL PRIMARY KEY,
  customer_id  BIGINT NOT NULL REFERENCES norm.customers(customer_id),
  order_ts     TIMESTAMPTZ NOT NULL DEFAULT now(),
  status       TEXT NOT NULL CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED'))
);

CREATE TABLE norm.order_items (
  order_id     BIGINT NOT NULL REFERENCES norm.orders(order_id) ON DELETE CASCADE,
  product_id   BIGINT NOT NULL REFERENCES norm.products(product_id),
  qty          INT NOT NULL CHECK (qty > 0),
  unit_price   NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  PRIMARY KEY (order_id, product_id)
);

CREATE TABLE norm.payments (
  payment_id   BIGSERIAL PRIMARY KEY,
  order_id     BIGINT NOT NULL REFERENCES norm.orders(order_id) ON DELETE CASCADE,
  paid_ts      TIMESTAMPTZ NOT NULL DEFAULT now(),
  amount       NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  method       TEXT CHECK (method IN ('CARD','BANK','CASH'))
);

-- Helpful indexes for joins and filtering
CREATE INDEX ON norm.orders (customer_id);
CREATE INDEX ON norm.orders (order_ts);
CREATE INDEX ON norm.order_items (product_id);
CREATE INDEX ON norm.payments (order_id);
```

Insert sample data
```
INSERT INTO norm.customers (full_name, email, region)
SELECT 'Customer '||g, 'c'||g||'@example.com', (ARRAY['NORTH','SOUTH','EAST','WEST'])[1 + (random()*3)::int]
FROM generate_series(1,200) g;

INSERT INTO norm.products (sku, name, unit_price)
SELECT 'SKU-'||g, 'Product '||g, round((10 + random()*490)::numeric,2)
FROM generate_series(1,500) g;

-- 5k orders over past 180 days
INSERT INTO norm.orders (customer_id, order_ts, status)
SELECT (1 + floor(random()*200))::int,
       now() - (random()*180||' days')::interval,
       (ARRAY['NEW','PAID','SHIPPED','CANCELLED'])[1 + (random()*3)::int]
FROM generate_series(1,5000) g;

-- Items per order (1–5)
INSERT INTO norm.order_items (order_id, product_id, qty, unit_price)
SELECT o.order_id,
       (1 + floor(random()*500))::int,
       (1 + floor(random()*5))::int,
       p.unit_price
FROM norm.orders o
JOIN LATERAL (SELECT unit_price FROM norm.products WHERE product_id = (1 + floor(random()*500))::int) p ON true
WHERE random() < 0.9;

-- Payments for PAID/SHIPPED orders
INSERT INTO norm.payments (order_id, paid_ts, amount, method)
SELECT o.order_id, o.order_ts + interval '1 hour',
       (SELECT sum(qty*unit_price) FROM norm.order_items oi WHERE oi.order_id = o.order_id),
       (ARRAY['CARD','BANK','CASH'])[1 + (random()*2)::int]
FROM norm.orders o
WHERE o.status IN ('PAID','SHIPPED');
```

Try to query with analyze
```
-- Monthly revenue by region
EXPLAIN ANALYZE
SELECT date_trunc('month', o.order_ts) AS month,
       c.region,
       SUM(oi.qty * oi.unit_price) AS revenue
FROM norm.orders o
JOIN norm.customers c ON c.customer_id = o.customer_id
JOIN norm.order_items oi ON oi.order_id = o.order_id
WHERE o.status IN ('PAID','SHIPPED')
GROUP BY 1,2
ORDER BY 1,2;
```

### 1.2 De-Normalization :: with new table
* Create a new table for summary

Create a new table
```
CREATE TABLE dnorm.order_fact (
  order_id     BIGINT PRIMARY KEY,
  order_ts     TIMESTAMPTZ NOT NULL,
  customer_id  BIGINT NOT NULL,
  customer_name TEXT NOT NULL,
  region       TEXT NOT NULL,
  status       TEXT NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL
);
```

Create sample data
```
-- Populate/refresh from normalized sources
INSERT INTO dnorm.order_fact
SELECT o.order_id, o.order_ts, c.customer_id, c.full_name, c.region, o.status,
       COALESCE((SELECT sum(qty*unit_price) FROM norm.order_items oi WHERE oi.order_id = o.order_id),0)
FROM norm.orders o
JOIN norm.customers c ON c.customer_id = o.customer_id
ON CONFLICT (order_id) DO NOTHING;

CREATE INDEX ON dnorm.order_fact (order_ts);
CREATE INDEX ON dnorm.order_fact (region);
```

Try to query with analyze
```
EXPLAIN ANALYZE
SELECT date_trunc('month', order_ts) AS month, region, SUM(total_amount) AS revenue
FROM dnorm.order_fact
WHERE status IN ('PAID','SHIPPED')
GROUP BY 1,2
ORDER BY 1,2;
```

### 1.3 De-Normalization :: Materialized Views
* Expensive aggregations (daily/weekly rollups)
* Stable queries where slightly stale data is OK
* Dashboards that don’t need second-level freshness

Create/refresh a materialized view for daily sales; enable concurrent refresh for zero-downtime 
```
-- Daily revenue per product (only PAID/SHIPPED)
CREATE MATERIALIZED VIEW dnorm.mv_daily_product_sales AS
SELECT date_trunc('day', o.order_ts)::date AS day,
       p.product_id,
       SUM(oi.qty * oi.unit_price) AS revenue,
       SUM(oi.qty) AS units
FROM norm.orders o
JOIN norm.order_items oi ON oi.order_id = o.order_id
JOIN norm.products p ON p.product_id = oi.product_id
WHERE o.status IN ('PAID','SHIPPED')
GROUP BY 1,2;

-- To REFRESH CONCURRENTLY, create a unique index that covers all rows
CREATE UNIQUE INDEX ON dnorm.mv_daily_product_sales (day, product_id);

-- Zero-downtime refresh
-- avoid blocking readers !!
REFRESH MATERIALIZED VIEW CONCURRENTLY dnorm.mv_daily_product_sales;
```

Query
```
SELECT * FROM dnorm.mv_daily_product_sales
WHERE day >= current_date - 14
ORDER BY day DESC, revenue DESC
LIMIT 50;
```

### 1.4 Discussion
* Normalized
  * pros = integrity, smaller writes, flexible
  * cons = joins in analytics
* Denormalized
  * pros = fast reads for common reports
  * cons = duplication, ETL/refresh complexity

## 2. Partitioning
* Use when data is large and naturally sliced by time or key
* Benefits: partition pruning, faster maintenance (detach/drop old), smaller indexes

### 2.1 Native Range Partitioning by Month (orders)
```
CREATE SCHEMA part;

CREATE TABLE part.orders (
  order_id     BIGSERIAL,
  customer_id  BIGINT NOT NULL REFERENCES norm.customers(customer_id),
  order_ts     TIMESTAMPTZ NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED')),
  PRIMARY KEY (order_id, order_ts)
) PARTITION BY RANGE (order_ts);
```

Create mounthly partitions
```
-- Helper to create monthly partitions (example: 2025)
DO $$
DECLARE
  m int;
  start_date date;
  end_date date;
  part_name text;
BEGIN
  FOR m IN 1..12 LOOP
    start_date := make_date(2025, m, 1);
    end_date   := (make_date(2025, m, 1) + INTERVAL '1 month')::date;
    part_name  := format('orders_%s', to_char(start_date, 'YYYY_MM'));
    EXECUTE format(
      'CREATE TABLE part.%I PARTITION OF part.orders
         FOR VALUES FROM (%L) TO (%L);',
      part_name, start_date, end_date
    );
    EXECUTE format('CREATE INDEX ON part.%I (customer_id);', part_name);
    EXECUTE format('CREATE INDEX ON part.%I (status);', part_name);
  END LOOP;
END$$;
```

Create default partition
```
-- Default partition to avoid insert errors outside range
CREATE TABLE part.orders_default PARTITION OF part.orders DEFAULT;
```

Insert data from norm.orders
```
-- Insert some data from norm.orders (recent months only)
INSERT INTO part.orders (order_id, customer_id, order_ts, status)
SELECT order_id, customer_id, order_ts, status
FROM norm.orders
WHERE order_ts >= date_trunc('year', now()); 
```

Query and Analyze
```
SELECT count(*)
FROM part.orders

EXPLAIN ANALYZE
SELECT count(*)
FROM part.orders
WHERE order_ts >= date_trunc('month', now()) - interval '1 month'
  AND order_ts <  date_trunc('month', now());


-- Create index on order_ts for better date range queries
CREATE INDEX ON part.orders (order_ts);
```

### 2.2 Partition Maintenance & Archiving
```
-- Detach old partition (> 24 months) to archive
-- Example: detach 2023_01 and move to archive schema
CREATE SCHEMA IF NOT EXISTS archive;

ALTER TABLE part.orders DETACH PARTITION part.orders_2023_01;
ALTER TABLE part.orders_2023_01 SET SCHEMA archive;

-- Optionally compress / store on cheaper storage, or export to S3, then DROP when allowed
-- Drop example:
-- DROP TABLE archive.orders_2023_01;
```


## 3. Sharding (Multiple nodes)
* Single node vs Multiple nodes
* Use when a single machine’s CPU/IO/Storage becomes the bottleneck or for geographic distribution
* Trade-offs
  * cross-shard joins become harder
  * you’ll rely on app-level routing or a coordinator


### 3.1 Simple Logical Sharding with a View & Routing Trigger (Single code)
* Keep two identical shard tables (e.g., by customer hash)
* Present a single UNION ALL view to the app
* Use an INSTEAD OF INSERT trigger on the view to route rows

Create schema and tables
```
CREATE SCHEMA shard;

-- Two shards in the same database (you can place shard_1 in another DB)
CREATE TABLE shard.orders_0 (LIKE norm.orders INCLUDING ALL);
CREATE TABLE shard.orders_1 (LIKE norm.orders INCLUDING ALL);

CREATE INDEX ON shard.orders_0 (customer_id);
CREATE INDEX ON shard.orders_1 (customer_id);
```

Create view
```
CREATE OR REPLACE VIEW shard.orders_all AS
SELECT * FROM shard.orders_0
UNION ALL
SELECT * FROM shard.orders_1;
```

Create function to routiung data by hash function
```
-- Routing function: even customer_id -> shard_0, odd -> shard_1
CREATE OR REPLACE FUNCTION shard.route_orders_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (NEW.customer_id % 2 = 0) THEN
    INSERT INTO shard.orders_0 VALUES (NEW.*);
  ELSE
    INSERT INTO shard.orders_1 VALUES (NEW.*);
  END IF;
  RETURN NULL; -- consumed by routed insert
END$$;
```

Create trigger on view
```
-- INSTEAD OF trigger on the view
CREATE TRIGGER trg_insert_orders_all
INSTEAD OF INSERT ON shard.orders_all
FOR EACH ROW EXECUTE FUNCTION shard.route_orders_insert();
```

Try to insert data
```
INSERT INTO shard.orders_all (order_id, customer_id, order_ts, status)
VALUES (1, 10, now(), 'NEW'), (2, 11, now(), 'PAID');
```

Query data from view
```
SELECT status, count(*) FROM shard.orders_all GROUP BY 1;
```



## 4. Data Housekeeping
* Retention strategy (how long to keep “hot” vs “warm” vs “cold” data)
* Archiving via partition detach, export, or COPY
* Vacuum/Analyze/Autovacuum tuning
  * index maintenance
  * bloat control
* Monitoring table growth and slow queries
* Safe online changes (CONCURRENT index builds, rolling refreshes)


### 4.1 Automate monthly archive + routine maintenance

Archival procedure: detach partitions older than N months
```
CREATE OR REPLACE PROCEDURE part.archive_old_partitions(months_back int)
LANGUAGE plpgsql AS $$
DECLARE
  part_rec record;
  cutoff date := (date_trunc('month', now()) - (months_back || ' months')::interval)::date;
  part_start date;
BEGIN
  FOR part_rec IN
    SELECT inhrelid::regclass AS child
    FROM pg_inherits
    WHERE inhparent = 'part.orders'::regclass
  LOOP
    -- Extract YYYY_MM from child name; adjust if your naming differs
    BEGIN
      part_start := to_date(regexp_replace(part_rec.child::text, '^.*_(\d{4})_(\d{2})$', '\1-\2-01'), 'YYYY-MM-DD');
    EXCEPTION WHEN others THEN
      CONTINUE;
    END;

    IF part_start < cutoff THEN
      EXECUTE format('ALTER TABLE part.orders DETACH PARTITION %s;', part_rec.child);
      EXECUTE format('ALTER TABLE %s SET SCHEMA archive;', part_rec.child);
    END IF;
  END LOOP;
END$$;
```

Call :: (keep last 24 months hot)
```
CALL part.archive_old_partitions(24);

ANALYZE part.orders;
```

Optional: use the pg_cron extension to schedule
```
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('monthly_archive', '0 3 1 * *', $$CALL part.archive_old_partitions(24)$$);

```