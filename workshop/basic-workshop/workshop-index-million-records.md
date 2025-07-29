# PostgreSQL Index Workshop: Scaling with Millions of Order Records
* PostgreSQL index types 
  * B-tree index
  * Hash index
  * GIN/BRIN for "inverted" index
  * Bitmap index

## 1. Generate data for testing

### 1.1 Create tables
```
-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS orders;

-- Create the orders table
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    total_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    product_details JSONB, -- For demonstrating GIN/inverted index concept
    delivery_address TEXT,
    notes TEXT
);
```
### 1.2 Create data for testing
```
-- Function to generate random data
CREATE OR REPLACE FUNCTION generate_random_orders(num_rows INT) RETURNS VOID AS $$
DECLARE
    i INT;
    random_customer_id INT;
    random_total_amount NUMERIC(10, 2);
    random_status TEXT;
    random_product_details JSONB;
    random_date TIMESTAMP;
    statuses TEXT[] := ARRAY['Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned'];
BEGIN
    FOR i IN 1..num_rows LOOP
        random_customer_id := floor(random() * 1000000) + 1; -- 1 to 1M customers
        random_total_amount := round((random() * 10000)::NUMERIC, 2); -- 0 to 10000
        random_status := statuses[floor(random() * array_length(statuses, 1)) + 1];
        random_date := NOW() - (random() * INTERVAL '5 years');

        -- Generate some varied product details for JSONB
        random_product_details := jsonb_build_object(
            'item_count', floor(random() * 10) + 1,
            'main_category', CASE floor(random()*3) WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Books' ELSE 'Apparel' END,
            'has_discount', (random() > 0.5)
        );

        INSERT INTO orders (customer_id, order_date, total_amount, status, product_details, delivery_address, notes)
        VALUES (
            random_customer_id,
            random_date,
            random_total_amount,
            random_status,
            random_product_details,
            'Address ' || i || ', City ' || (floor(random()*100)+1) || ', Zip ' || (floor(random()*90000)+10000),
            'Note ' || i || ' for order ' || random_customer_id
        );

        IF i % 100000 = 0 THEN
            RAISE NOTICE 'Inserted % rows', i;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Populate with 5 million records (adjust as needed for your system's capacity)
SELECT generate_random_orders(5000000);

-- Analyze the table after data insertion
ANALYZE orders;

-- Check record count
SELECT COUNT(*) FROM orders;
```
