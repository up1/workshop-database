-- Case 01: Generate 1 million orders + 10,000 customers
-- Uses generate_series for bulk insert performance

-- ============================================================
-- Helpers
-- ============================================================
CREATE OR REPLACE FUNCTION random_between(low INT, high INT)
RETURNS INT AS $$
    SELECT floor(random() * (high - low + 1) + low)::INT;
$$ LANGUAGE sql;

-- ============================================================
-- 10,000 customers
-- ============================================================
INSERT INTO customers (name, email)
SELECT
    first_names[1 + mod(i, array_length(first_names, 1))]
        || ' '
        || last_names[1 + mod(i / 10, array_length(last_names, 1))] AS name,
    'user' || i || '@example.com' AS email
FROM generate_series(1, 10000) AS i,
     LATERAL (SELECT ARRAY[
         'Alice','Bob','Carol','David','Eva','Frank','Grace','Henry',
         'Iris','James','Kate','Leo','Mia','Noah','Olivia','Paul',
         'Quinn','Rachel','Sam','Tina','Uma','Victor','Wendy','Xander',
         'Yara','Zoe'
     ] AS first_names) fn,
     LATERAL (SELECT ARRAY[
         'Johnson','Smith','White','Brown','Martinez','Davis','Wilson',
         'Moore','Taylor','Anderson','Thomas','Jackson','Harris','Martin',
         'Garcia','Thompson','Robinson','Clark','Lewis','Walker'
     ] AS last_names) ln;

-- ============================================================
-- 1,000,000 orders — spread over last 30 days
-- Mix of statuses; today's 'new' orders ~8,000 rows
-- ============================================================
INSERT INTO orders (customer_id, customer_name, status, total_amount, created_at)
SELECT
    cust_id,
    cust_name,
    CASE
        WHEN rnd_status < 0.20 THEN 'new'
        WHEN rnd_status < 0.50 THEN 'processing'
        WHEN rnd_status < 0.80 THEN 'shipped'
        WHEN rnd_status < 0.95 THEN 'delivered'
        ELSE                        'cancelled'
    END::order_status,
    round((random() * 9900 + 100)::numeric, 2),  -- 100.00 – 10000.00
    ts
FROM (
    SELECT
        (random() * 9999 + 1)::BIGINT                   AS cust_id,
        'Customer #' || (random() * 9999 + 1)::INT      AS cust_name,
        random()                                          AS rnd_status,
        -- 97% of orders: past 1-30 days; 3% of orders: today
        CASE WHEN random() < 0.03
            THEN CURRENT_DATE::TIMESTAMPTZ
                 + (random() * INTERVAL '23 hours 59 minutes')
            ELSE CURRENT_DATE::TIMESTAMPTZ
                 - (random() * INTERVAL '30 days')
                 - INTERVAL '1 second'
        END AS ts
    FROM generate_series(1, 1000000)
) sub;

-- ============================================================
-- Cleanup helper function
-- ============================================================
DROP FUNCTION IF EXISTS random_between(INT, INT);

-- ============================================================
-- Verify counts
-- ============================================================
SELECT
    'customers total'       AS label, COUNT(*) AS cnt FROM customers
UNION ALL
SELECT
    'orders total',                   COUNT(*) FROM orders
UNION ALL
SELECT
    'orders today new',               COUNT(*) FROM orders
    WHERE created_at >= CURRENT_DATE
      AND created_at <  CURRENT_DATE + INTERVAL '1 day'
      AND status = 'new'
UNION ALL
SELECT
    'orders today all statuses',      COUNT(*) FROM orders
    WHERE created_at >= CURRENT_DATE
      AND created_at <  CURRENT_DATE + INTERVAL '1 day';
