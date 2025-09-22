-- Create main schemas
CREATE SCHEMA IF NOT EXISTS norm; -- normalized OLTP
CREATE SCHEMA IF NOT EXISTS dnorm; -- denormalized/reporting


-- ========= Normalized model =========
CREATE TABLE IF NOT EXISTS norm.customers (
customer_id BIGSERIAL PRIMARY KEY,
full_name TEXT NOT NULL,
email TEXT UNIQUE NOT NULL,
region TEXT CHECK (region IN ('NORTH','SOUTH','EAST','WEST'))
);


CREATE TABLE IF NOT EXISTS norm.products (
product_id BIGSERIAL PRIMARY KEY,
sku TEXT UNIQUE NOT NULL,
name TEXT NOT NULL,
unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);


CREATE TABLE IF NOT EXISTS norm.orders (
order_id BIGSERIAL PRIMARY KEY,
customer_id BIGINT NOT NULL REFERENCES norm.customers(customer_id),
order_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
status TEXT NOT NULL CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED'))
);


CREATE TABLE IF NOT EXISTS norm.order_items (
order_id BIGINT NOT NULL REFERENCES norm.orders(order_id) ON DELETE CASCADE,
product_id BIGINT NOT NULL REFERENCES norm.products(product_id),
qty INT NOT NULL CHECK (qty > 0),
unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
PRIMARY KEY (order_id, product_id)
);


CREATE TABLE IF NOT EXISTS norm.payments (
payment_id BIGSERIAL PRIMARY KEY,
order_id BIGINT NOT NULL REFERENCES norm.orders(order_id) ON DELETE CASCADE,
paid_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
method TEXT CHECK (method IN ('CARD','BANK','CASH'))
);


-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer ON norm.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_ts ON norm.orders (order_ts);
CREATE INDEX IF NOT EXISTS idx_items_product ON norm.order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON norm.payments (order_id);


-- ========= Seed samples =========
-- 200 customers
INSERT INTO norm.customers (full_name, email, region)
SELECT 'Customer '||g, 'c'||g||'@example.com', (ARRAY['NORTH','SOUTH','EAST','WEST'])[1 + (random()*3)::int]
FROM generate_series(1,200) g
ON CONFLICT (email) DO NOTHING;


-- 500 products
INSERT INTO norm.products (sku, name, unit_price)
SELECT 'SKU-'||g, 'Product '||g, round((10 + random()*490)::numeric,2)
FROM generate_series(1,500) g
ON CONFLICT (sku) DO NOTHING;


-- 5k orders over past 180 days
INSERT INTO norm.orders (customer_id, order_ts, status)
SELECT (1 + floor(random()*200))::int,
now() - (random()*180||' days')::interval,
(ARRAY['NEW','PAID','SHIPPED','CANCELLED'])[1 + (random()*3)::int]
FROM generate_series(1,5000) g;


-- Items per order (1–5). Use product’s current price as unit_price snapshot
INSERT INTO norm.order_items (order_id, product_id, qty, unit_price)
SELECT o.order_id,
(1 + floor(random()*500))::int AS product_id,
(1 + floor(random()*5))::int AS qty,
(SELECT unit_price FROM norm.products p WHERE p.product_id = ((1 + floor(random()*500))::int))
FROM norm.orders o
WHERE random() < 0.9; -- ~90% of orders have items


-- Payments for PAID/SHIPPED orders
INSERT INTO norm.payments (order_id, paid_ts, amount, method)
SELECT o.order_id, o.order_ts + interval '1 hour',
COALESCE((SELECT sum(qty*unit_price) FROM norm.order_items oi WHERE oi.order_id = o.order_id),0),
(ARRAY['CARD','BANK','CASH'])[1 + (random()*2)::int]
FROM norm.orders o
WHERE o.status IN ('PAID','SHIPPED');