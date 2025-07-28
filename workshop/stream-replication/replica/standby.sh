#!/bin/bash
set -e

# Wait for primary to accept connections
until pg_isready -h primary -U postgres; do
  echo "Waiting for primary..."
  sleep 2
done

echo "Primary is ready, proceeding with replica setup."

# Clean data directory
rm -rf /var/lib/postgresql/data/*

# Base backup from primary
PGPASSWORD=replpass pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -Fp -Xs -P -R

echo "Base backup completed."

# Copy custom postgresql.conf if it exists
if [ -f /etc/postgresql/postgresql.conf ]; then
  echo "Copying custom postgresql.conf..."
  cp /etc/postgresql/postgresql.conf /var/lib/postgresql/data/postgresql.conf
fi

# Set proper ownership
chown -R postgres:postgres /var/lib/postgresql/data

echo "Starting PostgreSQL replica..."

# Clean up any existing shared memory segments and semaphores
ipcs -m | awk '/postgres/ {print $2}' | xargs -r ipcrm -m 2>/dev/null || true
ipcs -s | awk '/postgres/ {print $2}' | xargs -r ipcrm -s 2>/dev/null || true

# Remove any existing postmaster.pid file
rm -f /var/lib/postgresql/data/postmaster.pid

# Remove PostgreSQL lock files
rm -f /var/run/postgresql/.s.PGSQL.5432.lock
rm -f /tmp/.s.PGSQL.5432.lock
rm -f /var/run/postgresql/.s.PGSQL.5432

# Ensure /var/run/postgresql directory exists with proper permissions
mkdir -p /var/run/postgresql
chown postgres:postgres /var/run/postgresql

# Start PostgreSQL with proper configuration
exec postgres -D /var/lib/postgresql/data -c config_file=/var/lib/postgresql/data/postgresql.conf


