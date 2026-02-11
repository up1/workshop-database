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