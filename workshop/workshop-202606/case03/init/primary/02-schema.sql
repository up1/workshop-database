-- Case 03: Connection pooling and scaling
-- Simple orders table — focus is on pool routing, not schema complexity


-- CREATE OR REPLACE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replpass';

CREATE TYPE order_status AS ENUM ('new', 'processing', 'completed', 'cancelled');

CREATE TABLE orders (
    id            BIGSERIAL PRIMARY KEY,
    customer_id   BIGINT         NOT NULL,
    customer_name VARCHAR(255)   NOT NULL,
    status        order_status   NOT NULL DEFAULT 'new',
    total_amount  NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_created    ON orders (created_at DESC);
CREATE INDEX idx_orders_customer   ON orders (customer_id, created_at DESC);
CREATE INDEX idx_orders_status     ON orders (status, created_at DESC);
