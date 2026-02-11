# Workshop with Joins tables
* PostgreSQL Database


## 1. Create table `sales` and `customers`

Table `sales`:
```
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    quantity INTEGER,
    price_per_unit NUMERIC,
    store_location VARCHAR(50),
    customer_rating INTEGER
);

INSERT INTO sales (product_name, category, quantity, price_per_unit, store_location, customer_rating)
VALUES 
    ('Laptop', 'Electronics', 1, 1200, 'New York', 5),
    ('Mouse', 'Electronics', 3, 25, 'New York', NULL),
    ('Desk Chair', 'Furniture', 2, 150, 'Chicago', 4),
    ('Monitor', 'Electronics', 2, 300, 'Chicago', 3),
    ('USB Cable', 'Electronics', 10, 10, NULL, 5),
    ('Office Desk', 'Furniture', 1, 500, 'New York', 4),
    ('Keyboard', 'Electronics', 1, 45, 'Chicago', NULL);
```

Table `customers`:
```
-- 1. Create the Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    join_date DATE
);

-- 2. Add data to Customers
INSERT INTO customers (customer_name, email, join_date)
VALUES 
    ('John Doe', 'john@example.com', '2023-01-15'),
    ('Jane Smith', 'jane@example.com', '2023-05-20'),
    ('TechCorp Inc', 'contact@techcorp.com', '2023-11-02');

-- 3. Add a customer_id column to our existing sales table
ALTER TABLE sales ADD COLUMN customer_id INTEGER;

-- 4. Assign sales to specific customers
UPDATE sales SET customer_id = 1 WHERE sale_id IN (1, 2);
UPDATE sales SET customer_id = 2 WHERE sale_id IN (3, 4);
-- Sale_id 5, 6, 7 will have NULL customer_id (Guest Checkouts)

-- 5. Verify the data
SELECT * FROM sales;
SELECT * FROM customers;
```

## 2. Basic JOIN Example
* Inner Join
* Left Join
* Full Join

Inner Join:
```
-- Retrieve sales with customer details
SELECT 
    s.sale_id,
    s.product_name,
    c.customer_name,
    c.email
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id;
```

Left Join:
```
-- Retrieve all sales with customer details (if available)
SELECT 
    s.sale_id,
    s.product_name,
    c.customer_name,
    COALESCE(c.customer_name, 'Guest') AS buyer,
    c.email
FROM sales s
LEFT JOIN customers c ON s.customer_id = c.customer_id;
```

Full Join:
```
-- Retrieve all sales and all customers
SELECT 
    s.sale_id,
    s.product_name,
    c.customer_name,
    COALESCE(c.customer_name, 'Guest') AS buyer,
    c.email
FROM sales s
FULL JOIN customers c ON s.customer_id = c.customer_id;


