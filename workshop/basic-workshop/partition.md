# [Partition tables](https://www.postgresql.org/docs/current/ddl-partitioning.html)
* Horizontal partitioning

## Step 1 :: Enabled Partition pruning
* Query optimization technique that improves performance for declaratively partitioned tables

```
SHOW enable_partition_pruning;
```

## Step 2 :: Delete all tables
```
DROP TABLE book_category, 
           book_author, 
           book, 
           publisher,
           author, 
           category;
```

## Step 3 :: Create table book with range partitioning
```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE book (
    book_id UUID DEFAULT uuid_generate_v4(),
    isbn VARCHAR(14),
    title VARCHAR(255) NOT NULL,
    publication_date DATE NOT NULL,
    rating NUMERIC(4, 3),
    PRIMARY KEY (book_id, publication_date),
    UNIQUE (isbn, publication_date)
) PARTITION BY RANGE (publication_date);
```

## Step 4 :: Create range partition tables
```
CREATE TABLE book_y1990 PARTITION OF book
  FOR VALUES FROM ('1990-01-01') TO ('2000-01-01');

CREATE TABLE book_y2000 PARTITION OF book
  FOR VALUES FROM ('2000-01-01') TO ('2010-01-01');

CREATE TABLE book_y2010 PARTITION OF book
  FOR VALUES FROM ('2010-01-01') TO ('2020-01-01');
  
CREATE TABLE book_y2020 PARTITION OF book
  FOR VALUES FROM ('2020-01-01') TO ('2030-01-01');
```

## Step 5 :: Create index (apply for all partition table)
```
CREATE INDEX idx_book_part_key ON book (publication_date);
```

## Step 6 :: Generate data for test
```
INSERT INTO book (isbn, title, publication_date, rating)
SELECT SUBSTR(MD5(RANDOM()::TEXT), 0, 14), 
       MD5(RANDOM()::TEXT), 
       DATE '2010-01-01' + CAST(RANDOM() * (DATE '2024-01-01' - DATE '2010-01-01') AS INT),
       ROUND((1 + RANDOM() * 4)::numeric, 3)
FROM generate_series(1, 100000);
```

## Step 7 :: Query data in only one partition
```
EXPLAIN ANALYZE
SELECT EXTRACT(YEAR FROM b.publication_date) AS pub_year,
       COUNT(*)
FROM book b
WHERE b.publication_date > '2020-08-01' 
GROUP BY pub_year;
```

## Step 8 :: Query data in multiple partitions
```
EXPLAIN ANALYZE
SELECT EXTRACT(YEAR FROM b.publication_date) AS pub_year,
       COUNT(*)
FROM book b
WHERE b.publication_date > '2010-01-01' 
GROUP BY pub_year;
```
