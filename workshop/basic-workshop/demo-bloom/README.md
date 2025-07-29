# PostgreSQL Bloom Index Workshop: Efficient Username Existence Checks

## [Bloom Indexes](https://www.postgresql.org/docs/current/bloom.html) ?
* Space-efficient: They use significantly less space than traditional B-tree indexes for the same data
* Fast lookups: Membership tests are very quick
* Probabilistic: They can produce "false positives"
* Best for WHERE EXISTS or WHERE IN queries
* Multiple attributes with equality conditions

## Use cases ?
* Use a Bloom index to quickly determine if a username might exist in our users table
* Pre-checking before a more expensive lookup or an INSERT operation

## Create table
```
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255)  NOT NULL,
    email VARCHAR(255)  NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active'
);
```

## Insert data for testing
```
INSERT INTO users (username, email, status)
SELECT
    'user_' || LPAD(s::text, 7, '0'),
    'email_' || LPAD(s::text, 7, '0') || '@example.com',
    CASE WHEN (s % 2) = 0 THEN 'active' ELSE 'inactive' END
FROM generate_series(1, 1000000) AS s;


ANALYZE users;

-- Verify the count
SELECT COUNT(*) FROM users;
SELECT status, COUNT(*) FROM users GROUP BY status;
```

## Analyze your query
```
-- Test 1: Existing username and email (B-tree on username/email will be used)
EXPLAIN ANALYZE SELECT 1 FROM users WHERE username = 'user_0000001' AND email = 'email_0000001@example.com'; 

-- Test 2: Non-existing username and email (B-tree on username/email will be used)
EXPLAIN ANALYZE SELECT 1 FROM users WHERE username = 'non_existent_user_123' AND email = 'non_existent_email_123@example.com';

-- Test 3: Existing username, email, and status (B-tree might struggle without a composite index)
EXPLAIN ANALYZE SELECT 1 FROM users WHERE username = 'user_0000002' AND email = 'email_0000002@example.com' AND status = 'active';

-- Test 4: Non-existing combination (e.g., correct username/email but wrong status)
EXPLAIN ANALYZE SELECT 1 FROM users WHERE username = 'user_0000001' AND email = 'email_0000001@example.com' AND status = 'inactive';

```

## Create Bloom indexes
```
# Bloom index
CREATE EXTENSION bloom;
CREATE INDEX idx_users_multi_bloom ON users USING bloom (username, email, status);

# B-tree index
CREATE INDEX idx_users_multi_btree ON users (username, email, status);

CREATE INDEX idx_users_username_btree ON users (username);
CREATE INDEX idx_users_email_btree ON users (email);
CREATE INDEX idx_users_status_btree ON users (status);


ANALYZE users;
```

### Analysis !!
* The Index Only Scan on users_username_key (the B-tree index)
  * is very efficient for exact matches, even for non-existent values
  * B-trees are designed for fast lookups and range scans


## Test Performance
* B-tree vs Bloom index

## Size on indexes ?
```
SELECT
    pg_size_pretty(pg_relation_size('idx_users_multi_btree')) AS btree_index_size,
    pg_size_pretty(pg_relation_size('idx_users_multi_bloom')) AS bloom_index_size;


# Query all indexes in table users
SELECT 
    schemaname,
    relname,
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes 
WHERE relname = 'users'
ORDER BY pg_relation_size(indexrelid) DESC;
```