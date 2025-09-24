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