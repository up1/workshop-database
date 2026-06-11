# Case 01: List New Orders by Current Date

## Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| Timestamp column | `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` | Timezone-aware, auto-populated |
| Timezone | UTC only | Simple, no conversion needed |
| Volume | 10K–1M orders/day | B-tree index sufficient, partitioning not needed yet |
| Status type | PostgreSQL ENUM | Stored as int internally, faster than VARCHAR |
| Order ID | BIGSERIAL | Monotonic — works as keyset pagination tiebreaker |
| Customer name | Denormalized into orders | Customers table > 10M rows; JOIN too costly on hot path |
| Pagination | Keyset cursor on `(created_at, id)` | Constant speed at any page depth; OFFSET degrades at scale |
| Index | Composite `(created_at, status)` | Range on date narrows first, then status filter within |

## Steps

### Step 1: Create Schema

```bash
psql -U postgres -d orders -f schema.sql
```

### Step 2: Seed Test Data

```bash
psql -U postgres -d orders -f seed_data.sql
```

### Step 3: Run Queries

```bash
psql -U postgres -d orders -f queries.sql
```

---

## Key Query Pattern

### Wrong — function on column blocks index
```sql
-- BAD: created_at::date prevents index usage
SELECT * FROM orders
WHERE created_at::date = CURRENT_DATE
  AND status = 'new';
```

### Correct — range query uses B-tree index
```sql
-- GOOD: range scan on (created_at, status) index
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

### Keyset Pagination (page 2+)
```sql
-- Pass last row's (created_at, id) from previous page
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
  AND (created_at, id) < ($last_created_at, $last_id)
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

## Verify Index Usage

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, customer_name, status, total_amount, created_at
FROM orders
WHERE created_at >= CURRENT_DATE
  AND created_at < CURRENT_DATE + INTERVAL '1 day'
  AND status = 'new'
ORDER BY created_at DESC, id DESC
LIMIT 50;
```

Expected: `Index Scan using idx_orders_created_at_status` — not `Seq Scan`.
