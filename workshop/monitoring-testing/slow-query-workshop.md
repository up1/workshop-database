# Workshop :: Finding & Fixing Slow Queries with PostgreSQL Logs


## 1. Part 1: Preparation - Configure PostgreSQL Logging
```
log_min_duration_statement = 250 # in milliseconds. Set to a low value for testing (e.g., 0 for all queries)
                                 # but typically 100-1000 for production.
```

Check configuration
```
$show log_min_duration_statement;
```

## 2. Create Tables and Data for Testing

### Create a new database
```
CREATE DATABASE bookstore;

\c bookstore
```

### Create tables
```
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    bio TEXT,
    birth_date DATE
);

CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INT REFERENCES authors(author_id),
    genre_id INT REFERENCES genres(genre_id),
    publication_year INT,
    isbn VARCHAR(20) UNIQUE,
    price DECIMAL(10, 2),
    description TEXT
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    book_id INT REFERENCES books(book_id),
    customer_name VARCHAR(100),
    rating INT CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Generate test data
```
-- Insert Genres
INSERT INTO genres (genre_name) VALUES
('Fiction'), ('Science Fiction'), ('Fantasy'), ('Mystery'), ('Thriller'),
('Romance'), ('Horror'), ('Historical Fiction'), ('Biography'), ('Poetry');

-- Insert Authors (1000 authors)
INSERT INTO authors (first_name, last_name, birth_date)
SELECT
    'AuthorFN' || i,
    'AuthorLN' || i,
    (CURRENT_DATE - (i * 100 * '1 day'::interval))::date
FROM generate_series(1, 1000) AS i;

-- Insert Books (500,000 books)
INSERT INTO books (title, author_id, genre_id, publication_year, isbn, price, description)
SELECT
    'Book Title ' || i || ' - The ' || (CASE WHEN i % 3 = 0 THEN 'Mystery' WHEN i % 5 = 0 THEN 'Epic' ELSE 'Adventure' END),
    (i % 1000) + 1, -- Link to authors
    (i % 10) + 1,   -- Link to genres
    1900 + (i % 125), -- Publication year
    '978-1-' || LPAD((i * 100)::text, 8, '0') || '-' || LPAD((i % 10)::text, 1, '0'), -- ISBN
    (RANDOM() * 50 + 10)::DECIMAL(10,2), -- Price between 10 and 60
    'This is a description for book number ' || i || '. It is a thrilling tale of ' ||
    (CASE WHEN i % 7 = 0 THEN 'adventure' WHEN i % 11 = 0 THEN 'romance' ELSE 'intrigue' END) || '.'
FROM generate_series(1, 500000) AS i;

-- Insert Reviews (1,000,000 reviews)
INSERT INTO reviews (book_id, customer_name, rating, review_text)
SELECT
    (i % 500000) + 1,
    'Customer ' || i,
    (i % 5) + 1,
    'This book was ' || (CASE WHEN (i % 5) = 1 THEN 'terrible' WHEN (i % 5) = 2 THEN 'okay' WHEN (i % 5) = 3 THEN 'good' WHEN (i % 5) = 4 THEN 'great' ELSE 'amazing' END) || '.'
FROM generate_series(1, 1000000) AS i;
```

### Check size of test data
```
select count(*) from genres;
select count(*) from authors;  
select count(*) from books 
select count(*) from reviews;
```

### Analyzr tables !!
* After inserting large amounts of data, run ANALYZE to update statistics. This helps the query planner make good decisions
```
ANALYZE;
```

## 3. Step-by-Step to Create a Slow Query


## 4. Find the Slow Query in Logs


## 5. Solve the Slow Query