# Workshop with indexing

## Step 1 :: Query plan

Size/width of columns
```
EXPLAIN ANALYZE select * from books;

EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b;
```

Working with where clause
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = '1907';
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
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = '1907';
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
SELECT ROUND(COUNT(DISTINCT publication_year)::NUMERIC / count(*), 2) AS selectivity
FROM books;

SELECT ROUND(COUNT(DISTINCT price)::NUMERIC / COUNT(*), 2) AS selectivity
FROM books;

SELECT ROUND(COUNT(DISTINCT isbn)::NUMERIC / COUNT(*), 2) AS idx_selectivity
FROM books;

SELECT ROUND(COUNT(DISTINCT title)::NUMERIC / COUNT(*), 2) AS idx_selectivity
FROM books;
```


## Step 4 :: Working with B-tree index 
* Default index
* Index selective >= 0.85

### 4.1 Analyze query without index
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title = 'Book Title 5 - The Epic';
```

### 4.2 Create index in column `title`
```
CREATE INDEX idx_book_title ON books (title);
```

### 4.3 Analyze query with index
* Index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title = 'Book Title 5 - The Epic';
```

### 4.4 Analyze query with index and filter by unindexed column
* Index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title = 'Book Title 5 - The Epic'
AND b.price > 20; --unindexed column
```

### 4.5 Analyze query
* Seq scan
```
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907;
```

## Step 5 :: Working with index
1. Create index
```
CREATE INDEX idx_book_pub_year ON books (publication_year);
```

2. Analyze query
* Bitmap index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907;
```

Too many rows matches !!
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year > 1907;

# Use a Partial Index (if you always filter by this condition)
CREATE INDEX idx_books_pub_year_partial
ON books (publication_year)
WHERE publication_year > 1907;

# Use a BRIN Index
CREATE INDEX idx_books_pub_year_brin
ON books USING BRIN (publication_year);


# Force Index Usage (not recommended unless for testing)
SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT isbn, title, publication_year, price
FROM books
WHERE publication_year > 1907;

SET enable_seqscan = ON;  -- reset
```

### Query has low selectivity 
* meaning a large portion of the table matches publication_year > 1907
* PostgreSQL prefers a Seq Scan, and your index is not helping.

### When Index Will Be Used
You’re more likely to see index usage when:
* Less than ~10% of rows match the condition.
* The table is large (thousands+ of rows).
* Stats are fresh (ANALYZE run).

You use a partial or covering index.

3. Bitmap scan :: combine multiple indexs using bitmap (AND, OR)
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
AND b.price > 20;
```

Create index for price
```
CREATE INDEX idx_book_price ON books (price);
```

## Step 6 :: Working with multi-columns indexs

Index selectivity
* publication_year and price
```
SELECT ROUND((
  SELECT COUNT(*) AS count_distinct FROM (
    SELECT DISTINCT publication_year, price FROM books
  ) AS t)::NUMERIC / COUNT(*), 2) AS selectivity
FROM books;
```

Result = 1 (Good index)

Drop single index
```
DROP INDEX idx_book_pub_year, idx_book_price;
```

Create multi-columns index
```
CREATE INDEX idx_book_pub_year_price ON books (publication_year, price);

ANALYZE books;
```

Analyze query again with Bitmap Heap Scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
AND b.price > 20;
```

## Step 7 :: Bad performance of multi-columns indexs

Partial where clause with publication_date
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
```

Partial where clause with rating
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.price = 20;
```

Not working with OR !!
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
OR b.price = 20;
```

## Step 8 :: [Index only scan](https://www.postgresql.org/docs/current/indexes-index-only-scans.html)
* Fetche data directly from the index without reading the table data entirely
* Most efficient type of scanning

```
EXPLAIN ANALYZE
SELECT b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1970;
```

## Step 8 :: Unique index
* A unique index guarantees that the table column values won't have duplicates

Create table with UNIQUE
```
CREATE TABLE books (
    book_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    isbn VARCHAR(14) UNIQUE,
    title VARCHAR(255) NOT NULL
);
```

Create index
```
CREATE UNIQUE INDEX book_isbn_key ON books (isbn);
```

Analyze query
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.isbn = 'cdb352a260bd3';
```

## Step 9 :: Working with partial indexs


Create index
```
CREATE INDEX idx_book_pub_date_price_part on books (publication_year) WHERE price > 20;
```

Analyze query with price > 20
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
AND b.price > 20
```

Analyze query with price > 30
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
AND b.price > 30
```

Analyze query with price > 10
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.publication_year = 1907
AND b.price > 10
```

## Step 10 :: Working with [GIN index](https://www.postgresql.org/docs/current/indexes-types.html)
* Inverted indexes
* Better for search data

Analyze query with search data
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title LIKE '%Title%';
```

Create extension with trigram GIN index
```
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_book_title_trgm ON books USING gin (title gin_trgm_ops);

ANALYZE books;
```

Analyze query with search data
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title LIKE '%Title%';
```

Working with bitmap operation
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title LIKE '%Title%'
AND b.publication_year = 1970;
```

## Step 11 :: Working with hash indexs
* Flat structure
* Hash indexes can only handle simple equality comparisons (using the = operator)
* On a very large data sets Hash indexes takes less space compared to B-Tree

Explain query
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title = 'Book Title 1 - The Adventure'
```

Create index
```
DROP INDEX idx_book_title;

CREATE INDEX idx_book_title_hash ON books USING HASH (title);
```

Explain query again
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_year,
       b.price
FROM books b
WHERE b.title = 'Book Title 1 - The Adventure'
```

## Step 12 :: Don't use over-index !!


Reset stat
```
SELECT pg_stat_reset();
```

Find indexws that never used
```
SELECT s.schemaname,
       s.relname AS table_name,
       s.indexrelname AS index_name,
       s.idx_scan AS times_used,
       pg_size_pretty(pg_relation_size(t.relid)) AS table_size,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       idx.indexdef AS index_ddl
  FROM pg_stat_user_indexes s
  JOIN pg_stat_user_tables t 
    ON s.relname = t.relname
  JOIN pg_index i
    ON s.indexrelid = i.indexrelid
  JOIN pg_indexes AS idx 
    ON s.indexrelname = idx.indexname
   AND s.schemaname = idx.schemaname
 WHERE s.idx_scan = 0 -- no scans
   AND 0 <> ALL(i.indkey) -- 0 in the array means this is an expression index
   AND NOT i.indisunique -- no unique index
 ORDER BY pg_relation_size(s.indexrelid) DESC;
```

Select data for all table
* [Routine Vacuuming](https://www.postgresql.org/docs/current/routine-vacuuming.html)

```
SELECT schemaname, 
       relname, 
       last_vacuum, 
       vacuum_count, 
       last_analyze, 
       analyze_count 
FROM pg_stat_user_tables;
```