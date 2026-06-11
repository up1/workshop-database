-- Case 02: Seed 1 million orders into partitioned table
-- Spread evenly across Jul 2025 – Jun 2026 (12 months, ~83K/month)
-- Reuses customers table from case01 (run case01/seed_data.sql first if needed)

-- ============================================================
-- Verify customers exist; seed if empty
-- ============================================================
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM customers) = 0 THEN
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
        RAISE NOTICE 'Seeded 10,000 customers.';
    ELSE
        RAISE NOTICE 'Customers already exist, skipping.';
    END IF;
END;
$$;

-- ============================================================
-- 1,000,000 orders spread across Jul 2025 – Jun 2026
-- Each month: ~83,333 orders
-- Today (2026-06): ~3% of June orders flagged as today
-- ============================================================
INSERT INTO orders_partitioned (customer_id, customer_name, status, total_amount, created_at)
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
    round((random() * 9900 + 100)::numeric, 2),
    ts
FROM (
    SELECT
        (random() * 9999 + 1)::BIGINT              AS cust_id,
        'Customer #' || (random() * 9999 + 1)::INT AS cust_name,
        random()                                    AS rnd_status,
        -- Spread orders across 12 months: 2025-07-01 to 2026-06-30
        -- Last 11 months: uniform random in past
        -- Current month (Jun 2026): 97% spread across June, 3% = today
        CASE
            WHEN random() < (11.0 / 12.0) THEN
                -- Random timestamp in Jul 2025 – May 2026 (11 months = 334 days)
                TIMESTAMPTZ '2025-07-01 00:00:00+00'
                + (random() * INTERVAL '334 days')
            WHEN random() < 0.97 THEN
                -- June 2026 but not today (days 1–10)
                TIMESTAMPTZ '2026-06-01 00:00:00+00'
                + (random() * INTERVAL '10 days')
            ELSE
                -- Today (2026-06-11): simulate today's incoming orders
                CURRENT_DATE::TIMESTAMPTZ
                + (random() * INTERVAL '23 hours 59 minutes')
        END AS ts
    FROM generate_series(1, 1000000)
) sub;

-- ============================================================
-- Verify row counts per partition
-- ============================================================
SELECT
    tableoid::regclass AS partition,
    COUNT(*)           AS row_count
FROM orders_partitioned
GROUP BY tableoid
ORDER BY tableoid::regclass::text;

-- Totals sanity check
SELECT
    'total orders'              AS label, COUNT(*)    FROM orders_partitioned
UNION ALL
SELECT
    'today new orders',                   COUNT(*)
    FROM orders_partitioned
    WHERE created_at >= CURRENT_DATE
      AND created_at <  CURRENT_DATE + INTERVAL '1 day'
      AND status = 'new'
UNION ALL
SELECT
    'unique customers with orders',       COUNT(DISTINCT customer_id)
    FROM orders_partitioned;
