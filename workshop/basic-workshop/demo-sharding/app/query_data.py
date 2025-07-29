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

def get_orders_by_customer(customer_id):
    shard_id = get_shard_id(customer_id)
    conn = None
    orders = []
    try:
        conn = get_shard_connection(shard_id)
        cur = conn.cursor()
        cur.execute("""
            SELECT order_id, customer_id, order_date, total_amount, status
            FROM orders
            WHERE customer_id = %s
        """, (customer_id,))
        orders = cur.fetchall()
        cur.close()
    except Exception as e:
        print(f"Error querying shard {shard_id} for customer {customer_id}: {e}")
    finally:
        if conn:
            conn.close()
    return orders   

if __name__ == "__main__":
    # Example usage: Fetch orders for a specific customer
    customer_id = random.randint(1, 10000)  # Random customer ID
    orders = get_orders_by_customer(customer_id)
    if orders:
        print(f"Orders for customer {customer_id}:")
        for order in orders:
            print(order)
    else:
        print(f"No orders found for customer {customer_id}.")