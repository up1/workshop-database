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
