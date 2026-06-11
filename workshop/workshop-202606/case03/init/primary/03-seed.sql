-- Seed 50,000 orders spread over the last 365 days
INSERT INTO orders (customer_id, customer_name, status, total_amount, created_at)
SELECT
    (random() * 9999 + 1)::BIGINT,
    'Customer ' || (random() * 9999 + 1)::INT,
    (ARRAY['new','processing','completed','cancelled'])[floor(random() * 4 + 1)]::order_status,
    round((random() * 9999 + 1)::NUMERIC, 2),
    now() - (random() * INTERVAL '365 days')
FROM generate_series(1, 50000);
