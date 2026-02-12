# Workshop with Basic SQL
* PostgreSQL Database



## 1. Create table `employee`
```
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    email VARCHAR(50) UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC
);
```

## 2. Insert a new employee
```
INSERT INTO employees (email, first_name, last_name, department, salary)
VALUES ('demo1@gmail.com', 'Alice', 'Smith', 'IT', 75000),
       ('demo2@gmail.com', 'Bob', 'Jones', 'HR', 55000);


INSERT INTO employees (email, first_name, last_name, department, salary)
VALUES ('demo3@gmail.com', 'Charlie', 'Brown', NULL, 45000);
```

Generate 10,000 rows
```
-- Insert sample data  10,000 rows
INSERT INTO employees (email, first_name, last_name, department, salary)
SELECT
    'user' || generate_series(1, 10000) || '@example.com' AS email,
    'FirstName' || generate_series(1, 10000) AS first_name,
    'LastName' || generate_series(1, 10000) AS last_name,
    CASE
        WHEN (random() * 4)::int = 0 THEN 'HR'  
        WHEN (random() * 4)::int = 1 THEN 'Engineering'
        WHEN (random() * 4)::int = 2 THEN 'Sales'
        ELSE 'Marketing'
    END AS department,
    (random() * 90000 + 30000)::numeric AS salary;  
```

## 3. Query all data
* [SELECT](https://www.postgresql.org/docs/current/sql-select.html)
```
SELECT * 
FROM employees;


SELECT first_name, salary 
FROM employees;

```

## 4. Query data (filter with condition)
* WHERE clause
* Operators:  =, >, <, LIKE, IN
```
SELECT * FROM employees 
WHERE salary > 50000;

SELECT * FROM employees 
WHERE department IS NULL;

-- Using COALESCE to provide a default value
SELECT first_name, COALESCE(department, 'Unassigned') as dept
FROM employees;

-- Filtering by multiple conditions
SELECT * FROM employees 
WHERE salary < 50000
AND department IS NULL;


SELECT * FROM employees
WHERE salary > 50000 
AND department = 'IT';


-- Using LIKE for pattern matching (names starting with 'A')
SELECT * FROM employees
WHERE first_name LIKE 'A%';
```

## 5. Aggregate data
* [Aggregate functions](https://www.postgresql.org/docs/current/tutorial-agg.html)
  * COUNT, SUM, AVG, MIN, and MAX

```
-- Calculate the total payroll and average salary
SELECT 
    COUNT(*) as total_staff,
    SUM(salary) as total_payroll,
    AVG(salary) as average_salary
FROM employees;
```

## 6. Summarizing Data
* GROUP BY
```
-- Summarizing data by department
SELECT 
    department, 
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 2) as avg_dept_salary
FROM employees
WHERE department IS NOT NULL
GROUP BY department
ORDER BY avg_dept_salary DESC;
```

## 7. Data Manipulation and Transformation
```
-- Transforming data on the fly
SELECT 
    UPPER(last_name) as surname,
	salary,
    salary * 1.10 as salary_with_bonus,
    CASE 
        WHEN salary > 60000 THEN 'High'
        ELSE 'Standard'
    END as salary_level
FROM employees;
```

## 8. Workshop :: Try by yourself
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

Write SQL query from business questions
1. Handle Missing Data: Show all sales, but if the store_location is NULL, display it as 'Online'.
2. Transformation: Create a column called total_revenue (quantity * price).
3. Conditional Logic: Create a column called rating_status. If the rating is 5, call it 'Excellent'. If it's 3 or 4, call it 'Good'. For anything else (including NULL), call it 'Average'.
4. Filtering: Only include rows where the category is 'Electronics'.
5. Summarization: Group the data by your new location field and show the total revenue and average rating for each.


Answer
```
SELECT 
    COALESCE(store_location, 'Online') AS location,
    SUM(quantity * price_per_unit) AS total_revenue,
    ROUND(AVG(customer_rating), 2) AS avg_rating,
    COUNT(*) FILTER (WHERE customer_rating IS NOT NULL) AS rated_count,
    CASE
      WHEN AVG(customer_rating) >= 5 THEN 'Excellent'
      WHEN AVG(customer_rating) >= 3 THEN 'Good'
      ELSE 'Average'
    END AS customer_rating_level,
    COUNT(*) AS transaction_count
FROM sales
WHERE category = 'Electronics'
GROUP BY COALESCE(store_location, 'Online')
ORDER BY total_revenue DESC;
```