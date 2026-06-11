#!/bin/bash
set -e

# Create replication user (no password — trust auth for workshop)
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION;
EOSQL

# Allow replication connections from any Docker network host (workshop only)
echo "host  replication  replicator  all  trust" >> "$PGDATA/pg_hba.conf"

pg_ctl reload -D "$PGDATA"
