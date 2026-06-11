# Case 03: Connection Pooling and Scaling

## Architecture

```
                         ┌─────────────────────────────────────────┐
                         │  Docker Compose                         │
                         │                                         │
  HTTP :3000             │  ┌─────────────────────────────────┐   │
  ─────────────────────► │  │  app (Node.js + Express)        │   │
                         │  │  PM2 cluster — 4 workers         │   │
                         │  │                                  │   │
                         │  │  primaryPool max=10 ──────────► │   │
                         │  │  replicaPool max=35 ──────────► │   │
                         │  └─────────┬──────────────┬────────┘   │
                         │            │              │             │
                         │     writes │        reads │             │
                         │            ▼              ▼             │
                         │  ┌─────────────┐  ┌────────────────┐  │
                         │  │ db_primary  │  │  db_replica    │  │
                         │  │ :5432       │  │  :5433         │  │
                         │  │             │◄─│ WAL streaming  │  │
                         │  └─────────────┘  └────────────────┘  │
                         └─────────────────────────────────────────┘
```

## Connection caculation

| Variable | Value |
|---|---|
| PM2 workers | 4 |
| primaryPool.max per worker | 10 |
| replicaPool.max per worker | 35 |
| Total DB connections | 4 × (10 + 35) = **180** |
| Reserved for admin/migrations | 20 |
| postgres max_connections | 200 |

## Quick start

```bash
cd case03

# Install dependencies for app
npm install

# First run: builds app image + starts all services
docker compose up --build
docker compose ps

# Check replication lag
docker exec -it case03-db_primary-1 \
  psql -U user -d orders -c "SELECT * FROM pg_stat_replication;"

# Confirm replica is in standby mode
docker exec -it case03-db_replica-1 \
  psql -U user -d orders -c "SELECT pg_is_in_recovery();"
```

## API endpoints

| Method | Path | Pool | Description |
|---|---|---|---|
| GET | `/orders?limit=20&offset=0` | replica | List orders |
| POST | `/orders` | primary | Create order |
| GET | `/metrics` | both | Pool stats + pg_stat_activity |
| GET | `/health` | — | Liveness check |

### Create an order

```bash
curl -s -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_id":1,"customer_name":"Alice","status":"new","total_amount":99.99}' | jq
```

### List orders (served from replica)

```bash
curl -s "http://localhost:3000/orders?limit=5" | jq
```

### Watch pool stats

```bash
watch -n1 'curl -s http://localhost:3000/metrics | jq'
```

### Load test to see pool pressure

```bash
# Install
npm install -g autocannon

# Run load test for 10 seconds with 50 concurrent connections
autocannon -c 50 -d 10 http://localhost:3000/orders
```

## Reset

```bash
# Tear down + delete volumes (full reset including replica data)
docker compose down -v
```

## List of files in this case

- `docker-compose.yml` — services: db_primary, replica_init, db_replica, app
- `postgres/primary.conf` — PostgreSQL config with replication settings
- `init/primary/01-replication.sh` — creates `replicator` user, updates pg_hba.conf
- `init/primary/02-schema.sql` — orders table + indexes
- `init/primary/03-seed.sql` — 50,000 seed rows
- `app/src/db.js` — two pg.Pool instances (primary + replica)
- `app/src/routes/orders.js` — read/write routing
- `app/src/routes/metrics.js` — pool stats + pg_stat_activity
- `app/ecosystem.config.js` — PM2 cluster config (4 workers)
