# Workshop with indexing

## Step 1 :: Query plan

Size/width of columns
```
EXPLAIN ANALYZE select * from book;

EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
  FROM book b;
```

Working with where clause
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
  FROM book b
 WHERE b.publication_date = '2023-08-01';
```


## Step 2 :: Try with PostgreSQL again

Step 1 :: Reset statistics counters to zero
```
SELECT pg_stat_reset();
```

Step 2 :: Query data
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
  FROM book b
 WHERE b.publication_date = '2023-08-01';
```

Step 3 :: Get the suggestion what tables need an index by looking at seq_scan and seq_tup_read
```
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

## Step 3 :: Index selectivity
* Prefer indexing columns with selectivity greater than > 0.85

```
SELECT ROUND(COUNT(DISTINCT rating)::NUMERIC / COUNT(*), 2) AS selectivity
FROM book;

SELECT ROUND(COUNT(DISTINCT publication_date)::NUMERIC / count(*), 2) AS selectivity
FROM book;

SELECT ROUND(COUNT(DISTINCT isbn)::NUMERIC / COUNT(*), 2) AS idx_selectivity
FROM book;
```