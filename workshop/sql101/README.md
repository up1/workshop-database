# Workshop :: Basic of SQL with PostgreSQL
* Basic Syntax of SQL
* NULL Values
* Filtering with Conditions
* Aggregate Functions
* Data Manipulation and Transformation
* Summarizing Data

## Start database server with docker
```
$docker compose up -d db
$docker compose ps
```

PostgreSQL server
* Host: localhost
* Port: 5432
* User: root
* Password: root
* Database: test_db


## Create database
```
CREATE DATABASE ecommerce_workshop;
```


## Create table
  * Data types: INT, VARCHAR, TIMESTAMP, NUMERIC and NULL
```
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20),
    total_amount NUMERIC(10, 2),
    discount_code VARCHAR(20),
    shipping_city VARCHAR(50)
);
```

## Generate sample data
* Simple manual insert
```
INSERT INTO orders (customer_id, order_date, status, total_amount, discount_code, shipping_city) VALUES
(5001, '2024-01-01 10:00:00', 'Shipped', 150.00, 'SAVE10', 'New York'),
(5002, '2024-01-02 11:30:00', 'Pending', 85.50, NULL, 'Los Angeles'),
(5001, '2024-01-03 14:15:00', 'Shipped', 200.00, 'WELCOME', 'New York'),
(5003, '2024-01-04 09:45:00', 'Cancelled', 45.00, NULL, 'Chicago'),
(5004, '2024-01-05 16:20:00', 'Shipped', 310.00, 'SAVE10', 'Miami'),
(5002, '2024-01-06 12:00:00', 'Pending', 12.99, NULL, 'Los Angeles');
```

* Bulk generation more data with big data with `generate_series` and random functions
  * `generate_series` generates a series of numbers, which we can use to create multiple rows
  * `random()` generates a random number between 0 and 1, which we can use to create random values for our columns
  * `floor()` rounds down to the nearest integer, which we can use to create random integers for our columns
  * `CASE` allows us to create conditional logic for our columns, such as assigning a discount code to a certain percentage of orders
  * `ARRAY` allows us to create a list of values that we can randomly select from for our columns, such as order status and shipping city
```
INSERT INTO orders (customer_id, order_date, status, total_amount, discount_code, shipping_city)
SELECT 
    floor(random() * 100 + 5000)::int,                    -- Random Customer IDs 5000-5100
    now() - (random() * interval '30 days'),              -- Random dates in the last 30 days
    (ARRAY['Shipped', 'Pending', 'Cancelled', 'Returned'])[floor(random() * 4 + 1)], -- Random status
    (random() * 500)::numeric(10,2),                      -- Random amounts up to 500
    CASE WHEN random() > 0.7 THEN 'PROMO20' ELSE NULL END, -- 30% have a discount code (rest NULL)
    (ARRAY['London', 'Paris', 'Berlin', 'Tokyo'])[floor(random() * 4 + 1)]
FROM generate_series(1, 100);
```

## Counting and Filtering with Conditions
* Use `WHERE` clause to filter data based on conditions
```
SELECT COUNT(*) FROM orders; -- Total number of orders
SELECT COUNT(*) FROM orders WHERE status = 'Shipped'; -- Total shipped orders

SELECT * FROM orders WHERE status = 'Shipped';
SELECT * FROM orders WHERE total_amount > 100;
SELECT * FROM orders WHERE shipping_city = 'New York';

SELECT * 
FROM Orders 
WHERE total_amount > 100 AND status = 'Shipped';
```

### NULL Values
* NULL represents missing or unknown data
* NULL is not the same as an empty string or zero
* Use `IS NULL` and `IS NOT NULL` to filter NULL values

```
SELECT * FROM orders WHERE discount_code IS NULL;
SELECT * FROM orders WHERE discount_code IS NOT NULL;
```

## Aggregate Functions
* Aggregate functions perform calculations on a set of values and return a single value
* Common aggregate functions: COUNT, SUM, AVG, MAX, MIN

```
SELECT COUNT(*) FROM orders; -- Total number of orders
SELECT SUM(total_amount) FROM orders; -- Total revenue
SELECT AVG(total_amount) FROM orders; -- Average order amount
SELECT MAX(total_amount) FROM orders; -- Highest order amount
SELECT MIN(total_amount) FROM orders; -- Lowest order amount
SELECT shipping_city, COUNT(*) FROM orders GROUP BY shipping_city; -- Orders per city
SELECT status, SUM(total_amount) FROM orders GROUP BY status;

SELECT 
    SUM(total_amount) AS total_revenue, 
    AVG(total_amount) AS average_order_value,
    COUNT(order_id) AS total_orders
FROM Orders;
```

## Summarizing Data
* Use `GROUP BY` to group rows that have the same values in specified columns
```
SELECT shipping_city, COUNT(*) AS order_count, SUM(total_amount) AS total_revenue
FROM orders
GROUP BY shipping_city;

SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_revenue
FROM orders
GROUP BY status;

SELECT customer_id, COUNT(*) AS order_count, SUM(total_amount) AS total_spent
FROM orders
GROUP BY customer_id
ORDER BY total_spent DESC;
```

## Data Manipulation and Transformation
* Use `UPDATE` to modify existing records
```
UPDATE orders
SET status = 'Shipped'
WHERE order_id = 2;
```

* Use `DELETE` to remove records
```
DELETE FROM orders
WHERE order_id = 4;
```

* Use `ALTER TABLE` to modify table structure
```ALTER TABLE orders
ADD COLUMN payment_method VARCHAR(20);
```   

* Use `CASE` for conditional logic in queries
```
SELECT 
    order_id,
    total_amount,
    CASE 
        WHEN total_amount > 200 THEN 'High Value'
        WHEN total_amount > 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM orders;
```

## Create a "High Value" flag for orders over 150 and calculate a 5% tax for each order
```
SELECT 
    order_id,
    total_amount,
    total_amount * 0.05 AS tax_amount,
    CASE 
        WHEN total_amount > 150 THEN 'Premium'
        ELSE 'Standard'
    END AS order_category
FROM Orders;
```

## Write a query that shows the Total Revenue for each Customer, but only include Shipped orders where the customer spent more than $100 in total
* Use `GROUP BY` to group by customer_id and `HAVING` to filter groups based on the total revenue condition

```
SELECT 
    customer_id,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Shipped'
GROUP BY customer_id
HAVING SUM(total_amount) > 100;
```

* Order the results by total revenue in descending order
```
SELECT 
    customer_id,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Shipped'
GROUP BY customer_id
HAVING SUM(total_amount) > 100
ORDER BY total_revenue DESC;
```