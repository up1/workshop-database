import psycopg2

# Database connections (adjust credentials/ports as needed)
SHARD_CONFIG = {
    0: {"dbname": "shard_0_db", "user": "postgres", "password": "your_password", "host": "localhost", "port": "54320"},
    1: {"dbname": "shard_1_db", "user": "postgres", "password": "your_password", "host": "localhost", "port": "54321"},
    2: {"dbname": "shard_2_db", "user": "postgres", "password": "your_password", "host": "localhost", "port": "54322"},
}
NUM_SHARDS = len(SHARD_CONFIG)

def get_shard_connection(shard_id):
    config = SHARD_CONFIG[shard_id]
    return psycopg2.connect(**config)

def get_shard_id(customer_id):
    return customer_id % NUM_SHARDS