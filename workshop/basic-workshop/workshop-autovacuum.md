# Guide to tuning Autovacuum in PostgreSQL
* Goals
  * to make autovacuum more aggressive to keep up with high transaction rates
  * preventing table and index bloat
  * avoiding transaction ID wraparound issues

## 1. Establish a Monitoring Baseline

Enable Logging in file `postgresql.conf`
```
log_autovacuum_min_duration = '0' # Logs all autovacuum actions
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ' # Adds useful context
```

Reload config
```
SELECT pg_reload_conf();
```

Identify Problem Tables
* tables with a high number of dead tuples (n_dead_tup)
* tables that haven't been vacuumed recently (last_autovacuum)

```
SELECT
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    last_autovacuum,
    last_autoanalyze
FROM
    pg_stat_user_tables
WHERE
    n_dead_tup > 10000 -- Adjust this threshold for your DB size
ORDER BY
    n_dead_tup DESC;
```

## 2. Adjust Global Autovacuum Settings
* Increase Worker Capacity
* Make Autovacuum More Responsive
* Provide More Memory

```
autovacuum_max_workers = 4 # Default is 3

autovacuum_naptime = '15s' # Default is 1min
autovacuum_vacuum_cost_delay = '1ms' # Default is 2ms in PG17

maintenance_work_mem = '512MB' -- Default is 64MB. Adjust based on available RAM.
```