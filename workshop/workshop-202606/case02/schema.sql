-- Case 02: Table partitioning for large datasets
-- Strategy: RANGE on created_at, monthly partitions
-- PK: (id, created_at) — partition key must be part of PK in PostgreSQL
-- Indexes: (created_at, status) for Pattern 1, (customer_id, created_at DESC) for Pattern 2

-- ============================================================
-- Cleanup (safe re-run)
-- ============================================================
DROP TABLE IF EXISTS orders_partitioned CASCADE;

-- ============================================================
-- Parent partitioned table
-- ============================================================
CREATE TABLE orders_partitioned (
    id            BIGSERIAL      NOT NULL,
    customer_id   BIGINT         NOT NULL,
    customer_name VARCHAR(255)   NOT NULL,
    status        order_status   NOT NULL DEFAULT 'new',
    total_amount  NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
    -- Partition key (created_at) must be part of the primary key
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- ============================================================
-- Monthly partitions: Jul 2025 – Jun 2026 (data range)
-- + Jul 2026 pre-created as next month buffer
-- Manual management: create before month starts to avoid insert failure
-- ============================================================
CREATE TABLE orders_partitioned_2025_07 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE orders_partitioned_2025_08 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE orders_partitioned_2025_09 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE orders_partitioned_2025_10 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE orders_partitioned_2025_11 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE orders_partitioned_2025_12 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE orders_partitioned_2026_01 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE orders_partitioned_2026_02 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE orders_partitioned_2026_03 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE orders_partitioned_2026_04 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE orders_partitioned_2026_05 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE orders_partitioned_2026_06 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

-- Pre-create next month before it arrives
CREATE TABLE orders_partitioned_2026_07 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

-- Create default partition for out-of-range data (optional, but prevents insert failures)
CREATE TABLE orders_partitioned_default PARTITION OF orders_partitioned
    DEFAULT;

-- ============================================================
-- Indexes on parent — PostgreSQL propagates to all partitions
-- ============================================================

-- Pattern 1: current date orders, sorted by created_at
-- Partition pruning eliminates all but current month partition
CREATE INDEX idx_orders_part_created_status
    ON orders_partitioned (created_at, status);

-- Pattern 2: orders by customer_id across all partitions
-- No partition pruning, but each partition uses this index
CREATE INDEX idx_orders_part_customer_created
    ON orders_partitioned (customer_id, created_at DESC);

-- ============================================================
-- Verify partition structure
-- ============================================================
SELECT
    parent.relname          AS parent_table,
    child.relname           AS partition_name,
    pg_get_expr(child.relpartbound, child.oid) AS partition_range
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
WHERE parent.relname = 'orders_partitioned'
ORDER BY child.relname;

-- Size of data and indexes for each partition (after inserting test data)
SELECT
    relname AS partition_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS indexes_size
FROM pg_catalog.pg_statio_user_tables
WHERE relname LIKE 'orders_partitioned_%'
ORDER BY relname;