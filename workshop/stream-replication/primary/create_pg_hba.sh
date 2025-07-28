#!/bin/bash
set -e

echo "host all all all $POSTGRES_HOST_AUTH_METHOD" >> /var/lib/postgresql/data/pg_hba.conf

# Create pg_hba.conf
cat <<EOF > /var/lib/postgresql/data/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Allow replication connections from the standby
local   all             all                                     trust
host    all             all             0.0.0.0/0               trust
host    replication     replicator      172.19.0.0/16           trust
EOF
