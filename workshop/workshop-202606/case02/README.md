# Case 02: Table Partitioning for Large Datasets

## Problem
Orders table: >100M rows, growing 10K–1M/day.

Two query patterns must stay fast:
1. List today's new orders, sorted by `created_at DESC`, with pagination
2. List orders by `customer_id`, sorted by `created_at DESC`, with pagination

## Partitioning Design

| Decision | Choice | Reason |
|----------|--------|--------|
| Partition type | `RANGE` | Query Pattern 1 prunes all past months |
| Partition key | `created_at` | Pattern 1 benefits most; Pattern 2 handled by index |
| Granularity | Monthly | 12 partitions/year; pruning still effective for daily queries |
| Primary key | `(id, created_at)` | PostgreSQL requires partition key in PK |
| Pattern 2 index | `(customer_id, created_at DESC)` | Defined on parent, propagated to all partitions |
| Partition management | Manual | Create next month's partition before month starts |

## Key Trade-off: PK Must Include Partition Key

Old PK: `PRIMARY KEY (id)` — **breaks on partitioned table**

New PK: `PRIMARY KEY (id, created_at)` — required by PostgreSQL

Consequence: foreign keys from other tables referencing `orders(id)` must also include `created_at`, or be dropped.

## Step-by-Step

### Step 1: Connect to database
```bash
docker compose exec db psql -U user -d orders
```

### Step 2: Apply schema
```bash
docker compose exec db psql -U user -d orders -f /sql/case02/schema.sql
```
Or from psql:
```sql
\i case02/schema.sql
```

Verify partitions created:
```sql
SELECT child.relname AS partition
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
WHERE parent.relname = 'orders_partitioned'
ORDER BY child.relname;
```
Expected: 13 rows (2025_07 through 2026_07)

### Step 3: Seed 1 million orders
```sql
\i case02/seed_data.sql
```
Takes ~10–30s. Verify:
```
total orders             | 1000000
today new orders         | ~600
unique customers          | ~10000
```

### Step 4: Run Pattern 1 — today's orders (partition pruning)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE created_at >= CURRENT_DATE
  AND created_at <  CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

**What to look for in EXPLAIN output:**
```
Partitions selected: 1 of 13
  -> Index Scan on orders_partitioned_2026_06
```
Only the current month partition is touched. 12 partitions eliminated.

### Step 5: Run Pattern 2 — orders by customer_id
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders_partitioned
WHERE customer_id = 42
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

**What to look for:**
```
  -> Index Scan on orders_partitioned_2025_07 (index cond: customer_id = 42)
  -> Index Scan on orders_partitioned_2025_08 (index cond: customer_id = 42)
  ...
```
All 12 partitions scanned, but each uses the `idx_orders_part_customer_created` index — fast per-partition, merge overhead is small.

### Step 6: Inspect partition sizes
```sql
\i case02/queries.sql
```

## Manual Partition Management Checklist

Before the 1st of each month, run:
```sql
-- Example: creating August 2026 before it starts
CREATE TABLE orders_partitioned_2026_08 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
```

**Warning:** If no partition exists for a date, INSERT fails with:
```
ERROR: no partition of relation "orders_partitioned" found for row
```

## Files

| File | Purpose |
|------|---------|
| `schema.sql` | Create partitioned table + 13 monthly partitions + indexes |
| `seed_data.sql` | Insert 1M orders across Jul 2025 – Jun 2026 |
| `queries.sql` | Pattern 1 & 2 queries + partition inspection |
