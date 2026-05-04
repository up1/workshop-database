# Workshop :: Basic of SQL with PostgreSQL
* Join tables to combine data from multiple tables based on related columns
* Types of joins: INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL OUTER JOIN
* Use JOIN to retrieve data from multiple tables in a single query
* Working with orders, products, and customers tables


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
    shipping_city VARCHAR(50) NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

## Generate Sample Data
```
-- Populate Customers
INSERT INTO customers (customer_name, email, city) VALUES
('Alice Johnson', 'alice@email.com', 'New York'),
('Bob Smith', 'bob@email.com', 'London'),
('Charlie Brown', 'charlie@email.com', 'Berlin'),
('Diana Prince', 'diana@email.com', 'Paris'); -- Customer with no orders

-- Populate Products
INSERT INTO products (product_name, price, category) VALUES
('Laptop', 1200.00, 'Electronics'),
('Mouse', 25.00, 'Accessories'),
('Keyboard', 75.00, 'Accessories'),
('Monitor', 300.00, 'Electronics');

-- Populate Orders
INSERT INTO orders (customer_id, product_id, order_date, status, total_amount, discount_code, shipping_city) VALUES
(1, 1, '2024-01-01 10:00:00', 'Shipped', 1200.00, 'SAVE10', 'New York'),
(1, 2, '2024-01-02 11:30:00', 'Pending', 25.00, NULL, 'New York'),
(2, 3, '2024-01-03 14:15:00', 'Shipped', 75.00, 'WELCOME', 'London'),
(3, 4, '2024-01-04 09:45:00', 'Cancelled', 300.00, NULL, 'Berlin'); 
```

Check data in all tables
```
SELECT * from customers;
SELECT * from products;
SELECT * from orders;
```

## Join workshop
* Use JOIN to combine data from customers, products, and orders tables


* Example: Retrieve all orders with customer names and product details
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
JOIN products p ON o.product_id = p.product_id;
```

### INNER JOIN(The "Matchmaker")

Returns only matching rows from both tables
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
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id;
```

### LEFT JOIN(The "Inclusive" Join)
Returns all rows from the left table and matching rows from the right table (NULL if no match)
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
LEFT JOIN products p ON o.product_id = p.product_id;
```

List all customers, including those who haven't bought anything yet 

```
SELECT 
    c.customer_name,
    o.order_id,
    p.product_name,
    o.order_date,
    o.status,
    o.total_amount,
    o.discount_code,
    o.shipping_city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN products p ON o.product_id = p.product_id;
```

### RIGHT JOIN(The "Right-Sided" Join)
Returns all rows from the right table and matching rows from the left table (NULL if no match
```SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    o.order_date,
    o.status,
    o.total_amount,
    o.discount_code,
    o.shipping_city
FROM orders o
RIGHT JOIN customers c ON o.customer_id = c.customer_id
RIGHT JOIN products p ON o.product_id = p.product_id;
```

### FULL OUTER JOIN (The "Complete Picture")
* Returns all rows when there is a match in either left or right table

Finding orphaned records (orders with deleted customers or customers with no orders)
```
SELECT c.customer_name, o.order_id
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id;
```

### Self Join
* A self join is a regular join but the table is joined with itself
* Useful for hierarchical data or comparing rows within the same table


Insert data for self join example
```
-- Alice's second order

INSERT INTO orders (customer_id, product_id, order_date, status, total_amount, discount_code, shipping_city) VALUES
(1, 3, '2024-01-05 12:00:00', 'Shipped', 75.00, NULL, 'New York'); 
``` 

Finding customers who have placed multiple orders
* Simple join
```
SELECT 
    c.customer_id, 
    c.customer_name, 
    COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 1;
```

* Self join to compare orders of the same customer
```
SELECT DISTINCT 
    c.customer_name, 
    o1.order_id AS first_order, 
    o2.order_id AS second_order
FROM orders o1
INNER JOIN orders o2 ON o1.customer_id = o2.customer_id
INNER JOIN customers c ON o1.customer_id = c.customer_id
WHERE o1.order_id < o2.order_id; 
-- Using '<' prevents duplicate pairs and matching the same order
```

### Join all three tables to find the total revenue generated by 'Alice Johnson'
```
SELECT SUM(o.total_amount)
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_name = 'Alice Johnson';
```