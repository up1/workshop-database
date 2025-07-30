-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'processing' CHECK (status IN ('processing', 'success')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pre-join summary table for optimized order details retrieval
CREATE TABLE IF NOT EXISTS order_summary (
    order_id INTEGER PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    products JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_summary_status ON order_summary(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Create trigger to update order_summary when orders or order_items change
CREATE OR REPLACE FUNCTION update_order_summary()
RETURNS TRIGGER AS $$
DECLARE
    order_rec RECORD;
    products_json JSONB;
    target_order_id INTEGER;
BEGIN
    -- Determine the order_id based on which table triggered the function
    IF TG_TABLE_NAME = 'orders' THEN
        target_order_id := COALESCE(NEW.id, OLD.id);
    ELSE -- TG_TABLE_NAME = 'order_items'
        target_order_id := COALESCE(NEW.order_id, OLD.order_id);
    END IF;
    
    -- Get order information
    SELECT o.id, o.total_price, o.status, o.created_at, o.updated_at
    INTO order_rec
    FROM orders o
    WHERE o.id = target_order_id;
    
    -- Aggregate products for this order
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', product_id,
            'name', product_name,
            'price', price,
            'quantity', quantity
        )
    ), '[]'::jsonb)
    INTO products_json
    FROM order_items
    WHERE order_id = order_rec.id;
    
    -- Insert or update order_summary
    INSERT INTO order_summary (order_id, total_price, status, products, created_at, updated_at)
    VALUES (order_rec.id, order_rec.total_price, order_rec.status, products_json, order_rec.created_at, order_rec.updated_at)
    ON CONFLICT (order_id)
    DO UPDATE SET
        total_price = EXCLUDED.total_price,
        status = EXCLUDED.status,
        products = EXCLUDED.products,
        updated_at = EXCLUDED.updated_at;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_order_summary_orders ON orders;
CREATE TRIGGER trigger_update_order_summary_orders
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_order_summary();

DROP TRIGGER IF EXISTS trigger_update_order_summary_items ON order_items;
CREATE TRIGGER trigger_update_order_summary_items
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW EXECUTE FUNCTION update_order_summary();
