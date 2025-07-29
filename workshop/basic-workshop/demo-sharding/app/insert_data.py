import psycopg2
import random
from datetime import datetime, timedelta

# Database connections (adjust credentials/ports as needed)
SHARD_CONFIG = {
    0: {"dbname": "shard_0_db", "user": "monitoring", "password": "monitorpass", "host": "localhost", "port": "5432"},
    1: {"dbname": "shard_1_db", "user": "monitoring", "password": "monitorpass", "host": "localhost", "port": "5432"},
    2: {"dbname": "shard_2_db", "user": "monitoring", "password": "monitorpass", "host": "localhost", "port": "5432"},
}
NUM_SHARDS = len(SHARD_CONFIG)

def get_shard_connection(shard_id):
    config = SHARD_CONFIG[shard_id]
    return psycopg2.connect(**config)

def get_shard_id(customer_id):
    return customer_id % NUM_SHARDS

def insert_order(customer_id, order_date, total_amount, order_status):
    shard_id = get_shard_id(customer_id)
    conn = None
    try:
        conn = get_shard_connection(shard_id)
        cur = conn.cursor()
        # CREATE TABLE orders (
#     order_id BIGSERIAL PRIMARY KEY,
#     customer_id INT NOT NULL,
#     order_date TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
#     total_amount NUMERIC(10, 2) NOT NULL,
#     status VARCHAR(50) NOT NULL,
#     product_details JSONB, -- For demonstrating GIN/inverted index concept
#     delivery_address TEXT,
#     notes TEXT
# );
        cur.execute("""
            INSERT INTO orders (customer_id, order_date, total_amount, status)
            VALUES (%s, %s, %s, %s)
        """, (customer_id, order_date, total_amount, order_status))
        conn.commit()
        cur.close()
    except Exception as e:
        print(f"Error inserting into shard {shard_id}: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

def generate_and_insert_orders(num_records):
    status_array = ['PENDING', 'COMPLETED', 'SHIPPED', 'CANCELLED', 'REFUNDED']
    start_date = datetime(2024, 1, 1)

    for i in range(num_records):
        customer_id_val = random.randint(1, 10000) # 1 to 10K customers
        order_date_val = start_date + timedelta(days=random.randint(0, 90))
        total_amount_val = round(random.uniform(10.0, 10000.0), 2)
        order_status_val = random.choice(status_array)

        insert_order(customer_id_val, order_date_val, total_amount_val, order_status_val)

        if (i + 1) % 100 == 0:
            print(f"Inserted {i+1} records.")

if __name__ == "__main__":
    print("Starting data generation for sharding...")
    generate_and_insert_orders(10000) # Insert 10,000 records
    print("Data generation complete.")