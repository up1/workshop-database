-- Case 01: Schema for listing new orders by current date

CREATE TYPE order_status AS ENUM ('new', 'processing', 'shipped', 'delivered', 'cancelled');

CREATE TABLE customers (
    id         BIGSERIAL    PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id            BIGSERIAL      PRIMARY KEY,
    customer_id   BIGINT         NOT NULL REFERENCES customers(id),
    customer_name VARCHAR(255)   NOT NULL,  -- snapshot at order time; denormalized to avoid JOIN
    status        order_status   NOT NULL DEFAULT 'new',
    total_amount  NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- Composite index: range scan on created_at, then filter status within that set
CREATE INDEX idx_orders_created_at_status ON orders (created_at, status);
