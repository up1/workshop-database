# Demo with Analyze SQL query


## Example :: Analyze a simple query that retrieves orders with total amount greater than $100
```
EXPLAIN ANALYZE SELECT * FROM orders WHERE total_amount > 100;
```

Result
```
Seq Scan on orders  (cost=0.00..1.09 rows=4 width=45) (actual time=0.011..0.013 rows=4.00 loops=1)"
  Filter: (total_amount > '100'::numeric)"
  Rows Removed by Filter: 3"
  Buffers: shared hit=1"

Planning:
  Buffers: shared hit=35"

"Planning Time: 0.243 ms"
"Execution Time: 0.025 ms"
```

Steps
* Seq Scan on orders: Postgres decided to read the entire `orders` table sequentially because there is no index on `total_amount`
  * cost=0.00..1.09: The estimated startup and total cost of the query
  * rows=4: The planner estimated that 4 rows would match the condition
  * width=45: The average size of each row in bytes
  * actual time=0.011..0.013: The actual time taken to execute this step, from start to finish
  * rows=4.00: The actual number of rows returned by this step (matches the estimate)
  * loops=1: This step was executed once
* Filter: (total_amount > '100'::numeric)
  * Postgres checked every row it read against this condition
* Rows Removed by Filter: 3
  * The table actually had 7 rows total. It kept 4 and threw away 3 because they didn't meet the > 100 criteria
* Buffers: shared hit=1
  * The data was already in the PostgreSQL buffer cache (RAM)
  * hit=1 means it read 1 block (8KB) from memory and 0 blocks from the physical disk
* Planning Time: 0.243 ms
  * How long it took Postgres to look at the query and decide on the "Seq Scan" strategy
* Execution Time: 0.025 ms
  * The actual time spent running the plan and fetching data

```
Note: In this specific run, the planning actually took 10x longer than the execution! 
This is very common with tiny tables or simple queries 
where the "thinking" takes more effort than the "doing"
```

Description of the output:
- The query planner chooses a sequential scan on the `orders` table to find rows where `total_amount` is greater than 100
- The actual time taken to execute the query is very low, indicating that the query is efficient for the given dataset

### Generate 1 million rows of data and analyze the same query again
```
INSERT INTO orders (customer_id, order_date, status, total_amount, discount_code, shipping_city)
SELECT 
    floor(random() * 100 + 5000)::int,                    -- Random Customer IDs 5000-5100
    now() - (random() * interval '30 days'),              -- Random dates in the last 30 days
    (ARRAY['Shipped', 'Pending', 'Cancelled', 'Returned'])[floor(random() * 4 + 1)], -- Random status
    (random() * 500)::numeric(10,2),                      -- Random amounts up to 500
    CASE WHEN random() > 0.7 THEN 'PROMO20' ELSE NULL END, -- 30% have a discount code (rest NULL)
    (ARRAY['London', 'Paris', 'Berlin', 'Tokyo'])[floor(random() * 4 + 1)]
FROM generate_series(1, 1000000);
```

Create index on total_amount
```
CREATE INDEX idx_total_amount ON orders(total_amount);
```



## Write a query that shows the Total Revenue for each Customer, but only include Shipped orders
* Use `GROUP BY` to group by customer_id and `WHERE` to filter for Shipped orders
```
SELECT 
    customer_id,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Shipped'
GROUP BY customer_id;
```

* Order the results by total revenue in descending order
```
SELECT 
    customer_id,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Shipped'
GROUP BY customer_id
ORDER BY total_revenue DESC;
```

## Analyze the query execution plan
* Use `EXPLAIN` to analyze the query execution plan
```
EXPLAIN ANALYZE SELECT 
    customer_id,
    SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Shipped'
GROUP BY customer_id
ORDER BY total_revenue DESC;
```
