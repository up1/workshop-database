# Workshop with index !!

## Query with price

Index selectivity
```
SELECT ROUND(COUNT(DISTINCT price)::NUMERIC / COUNT(*), 2) AS selectivity
FROM books;
```
Explain query
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.price > 20
```

## Monitoring
```
SELECT pg_stat_reset();

SELECT schemaname,
       relname as table_name,
       seq_scan, -- Number of sequential scans initiated on this table
       seq_tup_read, -- Number of live rows fetched by sequential scans
       idx_scan, -- Number of index scans initiated on this table
       idx_tup_fetch -- Number of live rows fetched by index scans
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC;
```

## Create index and explain !!

Simple
```
CREATE INDEX idx_book_price1 on books (price);
```

Partial index
```
CREATE INDEX idx_book_price_partial on books (price) WHERE price > 20;
```

Index-only scan or covering index
```
CREATE INDEX idx_book_all on books (isbn, title, publication_year,price);
CREATE INDEX idx_book_all_condition on books (isbn, title, publication_year,price) WHERE price > 20;
```

Cluster the table by price (re-order table by price)
```
CREATE INDEX idx_book_price1 on books (price);
CLUSTER books USING idx_book_price;
```

Materialized view or caching
* Pre-filter
Add maintenance overhead
```
CREATE MATERIALIZED VIEW book_price_gt20 AS
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.price > 20;


REFRESH MATERIALIZED VIEW book_price_gt20;

EXPLAIN ANALYZE SELECT * FROM book_price_gt20;
```


Query all table + total size estimated rows
```
SELECT relname AS table_name,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       n_live_tup AS estimated_rows
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;