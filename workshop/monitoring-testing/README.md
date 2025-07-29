# Monitoring with PostgreSQL
* PostgreSQL
* Prometheus
* PostgreSQL exporter
* Grafana
* Testing with [pgbench](https://www.postgresql.org/docs/current/pgbench.html)


## 1. Start PostgreSQL server
* Enable pg_stat_statements for query statistics
```
$docker compose up -d db
$docker compose ps
$docker-compose logs -f db
```

Access to container
```
$docker compose exec db bash

$psql -U monitoring -d postgres
```

Working with pg_stat_statements
```
# 1. Create extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

# 2. Reset
SELECT pg_stat_statements_reset();

# 3. Load test with pgbench

# 4. pg_stat_statements
SELECT query, calls, total_exec_time, mean_exec_time 
FROM pg_stat_statements 
WHERE total_exec_time > 200
ORDER BY total_exec_time DESC 
LIMIT 10;
```

List of parameters
* Show all parameters => show all;
* show max_connections;
* show shared_buffers;
* show work_mem;
* show wal_buffers;
* show effective_cache_size;
* show log_min_duration_statement;

## 2. Start testing with pgbench
```
$docker compose up -d pgbench
$docker compose ps
$docker-compose logs pgbench 
```

Try to Record transactions per second (TPS)


## 3. Iterative process
* Tweak one parameter at a time in `postgresql.conf`
* Re-run docker-compose up -d && docker-compose logs pgbench

```
$docker compose down
$docker volume prune
```

## 4. Monitoring with Prometheus annd Grafana

Start Postgres Exporter
```
$docker compose up -d postgres-exporter
$docker compose ps
```

Link to metrics
* http://localhost:9187

Start Prometheus
```
$docker compose up -d prometheus
$docker compose ps
```

Link to metrics
* http://localhost:9090
* http://localhost:9090/targets

Start Grafana
* [Dashboard for PostgreSQL](PostgreSQL Database)
```
$docker compose up -d grafana
$docker compose ps
```

Link to metrics
* http://localhost:3000
  * user=admin
  * password=passpord

