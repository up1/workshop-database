-- Case 01: Queries for listing new orders by current date

-- ============================================================
-- 1. BAD: function cast blocks index
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at::date = CURRENT_DATE
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- ============================================================
-- 2. GOOD: range query — uses idx_orders_created_at_status
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- ============================================================
-- 3. Keyset pagination — page 2
--    Replace $last_created_at and $last_id with last row values from page 1
-- ============================================================
-- Example: last row of page 1 was id=5, created_at='2026-06-11 10:30:00+00'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
  AND (created_at, id) < ('2026-06-11 10:30:00+00', 5)
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- ============================================================
-- 4. Verify index exists
-- ============================================================
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'orders';

-- ============================================================
-- 5. Count today's new orders (sanity check)
-- ============================================================
SELECT COUNT(*)
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new';

-- ============================================================
-- 6. Check size of data and index where table name is 'orders' and index name is 'idx_orders_created_at_status'
-- ============================================================
SELECT
    pg_size_pretty(pg_relation_size('orders')) AS table_size,
    pg_size_pretty(pg_relation_size('idx_orders_created_at_status')) AS index_size;


-- ============================================================
-- 7. Show slow queries (if any) that have been logged
--    Note: This requires log_min_duration_statement to be set to a value (e.g. 100ms) in postgresql.conf
-- ============================================================
CREATE EXTENSION pg_stat_statements;


-- Filter by table name 'orders' if needed
-- WHERE query LIKE '%orders%'
SELECT 
    calls, 
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER())::numeric, 2) AS percentage_of_total_cpu,
    query 
FROM pg_stat_statements 
WHERE query LIKE '%orders%' 
AND calls > 0
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Reset statistics after testing
SELECT pg_stat_statements_reset();
