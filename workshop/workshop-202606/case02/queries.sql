-- Case 02: Queries demonstrating partitioned table performance
-- Run EXPLAIN (ANALYZE, BUFFERS) to see partition pruning in action

-- ============================================================
-- PATTERN 1: Today's new orders — partition pruning demo
-- Only the current month partition (orders_partitioned_2026_06) is scanned
-- ============================================================

-- 1a. Show partition pruning: only 1 of 12 partitions scanned
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE created_at >= CURRENT_DATE
  AND created_at <  CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- 1b. Keyset pagination — page 2
-- Replace $last_created_at and $last_id with values from last row of page 1
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE created_at >= CURRENT_DATE
  AND created_at <  CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
  AND (created_at, id) < ('2026-06-11 10:30:00+00', 999999)
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- 1c. Count today's orders (partition pruning eliminates 11 partitions)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM orders_partitioned
WHERE created_at >= CURRENT_DATE
  AND created_at <  CURRENT_DATE + INTERVAL '1 day';

-- ============================================================
-- PATTERN 2: Orders by customer_id — cross-partition index scan
-- No partition pruning; each partition uses idx_orders_part_customer_created
-- ============================================================

-- 2a. List orders for customer #42, newest first (page 1)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE customer_id = 42
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- 2b. Keyset pagination for customer orders — page 2
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE customer_id = 42
  AND (created_at, id) < ('2026-03-15 08:00:00+00', 500000)
ORDER BY created_at DESC, id DESC
LIMIT 50;

-- ============================================================
-- Partition inspection
-- ============================================================

-- Show all partitions with row counts
SELECT
    tableoid::regclass              AS partition,
    COUNT(*)                        AS row_count,
    MIN(created_at)::date           AS earliest,
    MAX(created_at)::date           AS latest
FROM orders_partitioned
GROUP BY tableoid
ORDER BY tableoid::regclass::text;

-- Show partition boundaries from catalog
SELECT
    parent.relname                                          AS parent_table,
    child.relname                                           AS partition_name,
    pg_get_expr(child.relpartbound, child.oid)              AS partition_range,
    pg_size_pretty(pg_relation_size(child.oid))             AS data_size
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
WHERE parent.relname = 'orders_partitioned'
ORDER BY child.relname;

-- Show indexes propagated to all partitions
SELECT
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(pg_class.oid)) AS index_size
FROM pg_indexes
JOIN pg_class ON pg_class.relname = pg_indexes.indexname
WHERE tablename LIKE 'orders_partitioned%'
ORDER BY tablename, indexname;

-- ============================================================
-- Size comparison: total table vs individual partitions
-- ============================================================
SELECT
    pg_size_pretty(pg_total_relation_size('orders_partitioned')) AS total_size_with_indexes,
    pg_size_pretty(pg_relation_size('orders_partitioned'))        AS parent_size,
    (
        SELECT SUM(pg_relation_size(child.oid))
        FROM pg_inherits
        JOIN pg_class child ON pg_inherits.inhrelid = child.oid
        JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
        WHERE parent.relname = 'orders_partitioned'
    )::bigint                                                     AS partitions_bytes;
