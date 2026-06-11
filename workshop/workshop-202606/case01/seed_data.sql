-- Case 01: Seed data for testing

-- Customers
INSERT INTO customers (name, email) VALUES
    ('Alice Johnson',  'alice@example.com'),
    ('Bob Smith',      'bob@example.com'),
    ('Carol White',    'carol@example.com'),
    ('David Brown',    'david@example.com'),
    ('Eva Martinez',   'eva@example.com');

-- Orders: today (should appear in results)
INSERT INTO orders (customer_id, customer_name, status, total_amount, created_at) VALUES
    (1, 'Alice Johnson', 'new',        1500.00, now() - INTERVAL '10 minutes'),
    (2, 'Bob Smith',     'new',         850.50, now() - INTERVAL '30 minutes'),
    (3, 'Carol White',   'new',        2200.00, now() - INTERVAL '1 hour'),
    (4, 'David Brown',   'new',         499.99, now() - INTERVAL '2 hours'),
    (5, 'Eva Martinez',  'new',        3100.00, now() - INTERVAL '3 hours'),
    (1, 'Alice Johnson', 'new',         750.00, now() - INTERVAL '4 hours'),
    (2, 'Bob Smith',     'new',        1200.00, now() - INTERVAL '5 hours'),
    (3, 'Carol White',   'new',         320.00, now() - INTERVAL '6 hours');

-- Orders: today but NOT 'new' (should NOT appear)
INSERT INTO orders (customer_id, customer_name, status, total_amount, created_at) VALUES
    (1, 'Alice Johnson', 'processing',  980.00, now() - INTERVAL '2 hours'),
    (2, 'Bob Smith',     'shipped',    1100.00, now() - INTERVAL '4 hours'),
    (3, 'Carol White',   'cancelled',   450.00, now() - INTERVAL '6 hours');

-- Orders: yesterday (should NOT appear)
INSERT INTO orders (customer_id, customer_name, status, total_amount, created_at) VALUES
    (4, 'David Brown',  'new',         600.00, now() - INTERVAL '1 day'),
    (5, 'Eva Martinez', 'new',        1800.00, now() - INTERVAL '1 day'),
    (1, 'Alice Johnson','new',         250.00, now() - INTERVAL '2 days');
