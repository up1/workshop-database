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

## Step 4 :: Working with B-tree index 
* Default index
* Index selective >= 0.85

1. Analyze query without index
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title = 'Patterns of Enterprise Application Architecture';
```

2. Create index in column `title`
```
CREATE INDEX idx_book_title ON book (title);
```

3. Analyze query with index
* Index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title = 'Patterns of Enterprise Application Architecture';
```

4. Analyze query with index and filter by unindexed column
* Index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title = 'Patterns of Enterprise Application Architecture'
AND b.rating > 4; --unindexed column
```

5. Analyze query
* Seq scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01';
```

## Step 5 :: Working with Bitmap index
* Index selective < 0.85

1. Create index
```
CREATE INDEX idx_book_pub_date ON book (publication_date);
```

2. Analyze query
* Bitmap index scan
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01';
```

3. Bitmap scan :: combine multiple indexs using bitmap (AND, OR)
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01'
AND b.rating > 4;
```

Create index for rating
```
CREATE INDEX idx_book_rating ON book (rating);
```

## Step 6 :: Working with multi-columns indexs

Index selectivity
* publication_date and rating
```
SELECT ROUND((
  SELECT COUNT(*) AS count_distinct FROM (
    SELECT DISTINCT publication_date, rating FROM book
  ) AS t)::NUMERIC / COUNT(*), 2) AS selectivity
FROM book;
```

Result = 1 (Good index)

Drop single index
```
DROP INDEX idx_book_pub_date, 
           idx_book_rating;
```

Create multi-columns index
```
CREATE INDEX idx_book_pub_date_rating ON book (publication_date, rating);
```

Analyze query again
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01'
AND b.rating > 4;
```

## Step 7 :: Bad performance of multi-columns indexs

Partial where clause with publication_date
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01';
```

Partial where clause with rating
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
  FROM book b
 WHERE b.rating > 4;
```

Not working with OR
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01'
OR b.rating > 4;
```

## Step 8 :: [Index only scan](https://www.postgresql.org/docs/current/indexes-index-only-scans.html)
* Fetche data directly from the index without reading the table data entirely
* Most efficient type of scanning

```
EXPLAIN ANALYZE
SELECT b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date = '2023-08-01';
```

## Step 8 :: Unique index
* A unique index guarantees that the table column values won't have duplicates

Create table with UNIQUE
```
CREATE TABLE book (
    book_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    isbn VARCHAR(14) UNIQUE,
    title VARCHAR(255) NOT NULL,
    publication_date DATE NOT NULL,
    publisher_id UUID REFERENCES publisher(publisher_id),
    rating NUMERIC(4, 3)
);
```

Create index
```
CREATE UNIQUE INDEX book_isbn_key ON book (isbn);
```

Analyze query
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.isbn = 'cdb352a260bd3';
```

## Step 9 :: Working with partial indexs


Create index
```
CREATE INDEX idx_book_pub_date_rating_part on book (publication_date) WHERE rating > 4;
```

Analyze query with rating > 4
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01'
AND b.rating > 4;
```

Analyze query with rating > 3
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.publication_date > '2023-08-01'
AND b.rating > 3;
```

## Step 10 :: Working with [GIN index](https://www.postgresql.org/docs/current/indexes-types.html)
* Inverted indexes
* Better for search data

Analyze query with search data
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title LIKE 'Patterns%';
```

Create extension with trigram GIN index
```
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_book_title_trgm ON book USING gin (title gin_trgm_ops);
```

Analyze query with search data
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title LIKE 'Patterns%';
```

Working with bitmap operation
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title LIKE 'Patterns%'
AND b.publication_date = '2023-08-01';
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
       b.publication_date,
       b.rating
FROM book b
WHERE b.title = 'Patterns of Enterprise Application Architecture'
```

Create index
```
DROP INDEX idx_book_title;

CREATE INDEX idx_book_title_hash ON book USING HASH (title);
```

Explain query again
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
       b.publication_date,
       b.rating
FROM book b
WHERE b.title = 'Patterns of Enterprise Application Architecture'
```

## Step 12 :: More joins !!
* Join > Sub-query
```
EXPLAIN ANALYZE
SELECT b.isbn, 
       b.title,
	   b.publication_date,
	   a.full_name,
	   c.name
  FROM book b
  JOIN book_author ba 
    ON b.book_id = ba.book_id
  JOIN author a 
    ON a.author_id = ba.author_id
  JOIN book_category bc 
    ON b.book_id = bc.book_id
  JOIN category c 
    ON c.category_id = bc.category_id
 WHERE b.title LIKE '%Patterns%';
```

## Step 13 :: Don't use over-index !!


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