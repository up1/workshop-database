# Workshop :: Working with Large Data in SQL
* Handling large datasets in SQL
* Best practices for querying and managing large data
* Performance optimization techniques
* Use of indexes, partitioning, and efficient query design


## Create tables
```
-- 1. Customers Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50)
);

-- 2. Products Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price NUMERIC(10, 2),
    category VARCHAR(50)
);

-- 3. Orders Table (updated to include product_id)
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NULL,
    total_amount NUMERIC(10, 2) NULL,
    discount_code VARCHAR(20) NULL,
    shipping_city VARCHAR(50) NULL
    -- FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    -- FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

## Generate Sample Data 
* 1,000,000 rows for orders table
* 100,000 rows for customers table
* 10,000 rows for products table

```
-- Populate Customers (Fast Insert with CTEs)
INSERT INTO customers (customer_name, email, city)
WITH data AS (
    SELECT
        generate_series(1, 100000) as id,
        (ARRAY['New York', 'London', 'Berlin', 'Paris', 'Tokyo'])[floor(random() * 5 + 1)] as city
)
SELECT
    'Customer ' || id,
    'customer' || id || '@email.com',
    city
FROM data;    

-- Check number of rows in customers table
SELECT count(*) from customers;

-- Populate Products (Optimized with CTE)
INSERT INTO products (product_name, price, category)
WITH data AS (
    SELECT
        generate_series(1, 10000) as id,
        (ARRAY['Electronics', 'Accessories', 'Clothing', 'Home', 'Toys'])[floor(random() * 5 + 1)] as category
)
SELECT
    'Product ' || id,
    (random() * 1000)::numeric(10,2),
    category
FROM data;

-- Check number of rows in products table
SELECT count(*) from products;

-- Populate Orders (Optimized with CTE) 
INSERT INTO orders (customer_id, product_id, order_date, status, total_amount, discount_code, shipping_city)
WITH data AS (
    SELECT
        generate_series(1, 1000000) as id,
        floor(random() * 100000 + 1)::int as customer_id, -- Random customer_id from customers table
        floor(random() * 10000 + 1)::int as product_id, -- Random product_id from products table
        now() - (random() * interval '30 days') as order_date, -- Random dates in the last 30 days
        (ARRAY['Shipped', 'Pending', 'Cancelled', 'Returned'])[floor(random() * 4 + 1)] as status, -- Random status
        (random() * 500)::numeric(10,2) as total_amount, -- Random amounts up to 500
        CASE WHEN random() > 0.7 THEN 'PROMO20' ELSE NULL END as discount_code, -- 30% have a discount code (rest NULL)
        (ARRAY['London', 'Paris', 'Berlin', 'Tokyo'])[floor(random() * 4 + 1)] as shipping_city
)
SELECT
    customer_id,
    product_id,
    order_date,
    status,
    total_amount,
    discount_code,      
    shipping_city
FROM data;

-- Check number of rows in orders table
SELECT count(*) from orders;
```

## Querying Large Data
* Use LIMIT to restrict the number of rows returned
```
SELECT * FROM orders LIMIT 10;
```

* Use WHERE to filter data and reduce result set size
```
SELECT * FROM orders WHERE status = 'Shipped' LIMIT 10;

SELECT * FROM orders WHERE total_amount > 100 LIMIT 10;

SELECT * FROM orders WHERE shipping_city = 'Tokyo' LIMIT 10;
```

## Join with large data
* Use JOIN to combine data from customers, products, and orders tables
```
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    o.order_date,       
    o.status,
    o.total_amount,
    o.discount_code,
    o.shipping_city
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.total_amount > 100
LIMIT 10;
```

Use LEFT JOIN to include all orders even if customer or product details are missing
```
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    o.order_date,
    o.status,
    o.total_amount,
    o.discount_code,
    o.shipping_city
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN products p ON o.product_id = p.product_id
WHERE o.total_amount > 100
LIMIT 10;
```

## Improve Query Performance
* Use indexes on frequently queried columns (e.g., customer_id, product_id, order_date, status)
* Avoid SELECT * and only select necessary columns
* Use WHERE clauses to filter data early and reduce the number of rows processed
* Consider partitioning large tables by date or other relevant criteria for faster queries
* Use EXPLAIN to analyze query execution plans and identify bottlenecks
```
EXPLAIN SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    o.order_date,
    o.status,
    o.total_amount,
    o.discount_code,
    o.shipping_city
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE o.total_amount > 100
AND o.status = 'Shipped'
LIMIT 10;
```

Analize the output of EXPLAIN to see if indexes are being used and if there are any full table scans that can be optimized
* Bitmap indexes can be useful for low-cardinality columns like status
* B-tree indexes are good for high-cardinality columns like customer_id and product_id

Add indexes on relevant columns to improve performance
```
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_product_id ON orders(product_id);

-- total_amount and status are also commonly queried, consider indexing them as well
CREATE INDEX idx_orders_total_amount ON orders(total_amount);
CREATE INDEX idx_orders_status ON orders(status);
```

Composite indexes can also be beneficial for queries that filter on multiple columns
```
CREATE INDEX idx_orders_status_total_amount ON orders(status, total_amount);

CREATE INDEX idx_orders_status_amount_covering 
ON orders (status, total_amount)
INCLUDE (customer_id, product_id, order_id, order_date, discount_code, shipping_city);
```

## Order report by daily revenue
```
SELECT 
    DATE(order_date) AS order_day,
    SUM(total_amount) AS daily_revenue
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY order_day
ORDER BY order_day DESC;
```

## How to optimize this query for better performance?
* Ensure there is an index on order_date to speed up the date filtering
```
CREATE INDEX idx_orders_order_date ON orders(order_date);
```

* Consider partitioning the orders table by date to improve query performance for recent data
```
-- NOTE: In PostgreSQL, every UNIQUE/PRIMARY KEY on a partitioned table
-- MUST include all the partitioning columns. Since we partition by
-- `order_date`, it must be part of the primary key.
CREATE TABLE orders (
    order_id SERIAL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50),
    total_amount DECIMAL(10, 2),
    discount_code VARCHAR(50),
    shipping_city VARCHAR(100),
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

* Use EXPLAIN to analyze the query execution plan and ensure that indexes are being utilized effectively
```
EXPLAIN SELECT 
    DATE(order_date) AS order_day,
    SUM(total_amount) AS daily_revenue
FROM orders
WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY order_day
ORDER BY order_day DESC;
```

* Use pre-aggregated tables or materialized views if the daily revenue report is frequently accessed and does not require real-time data
```
CREATE MATERIALIZED VIEW daily_revenue AS
SELECT 
    DATE(order_date) AS order_day,
    SUM(total_amount) AS daily_revenue
FROM orders
GROUP BY order_day; 

-- Refresh the materialized view daily or as needed
REFRESH MATERIALIZED VIEW daily_revenue;
```
