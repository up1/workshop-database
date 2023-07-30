# Worlshop with slow query
* 

## Step 1 :: Enable extension `pg_stat_statements` to enable process to detect slow query
* [shared_preload_libraries=pg_stat_statements](https://www.postgresql.org/docs/current/runtime-config-client.html#RUNTIME-CONFIG-CLIENT-PRELOAD)
```
SHOW shared_preload_libraries;
```

## Step 2 :: 
```
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## Step 3 :: Get slowest query
```
SELECT SUBSTRING(query, 1, 40) AS short_query,
       ROUND(( 100 * total_exec_time / SUM(total_exec_time) OVER ())::NUMERIC, 2) AS percent,
       ROUND(total_exec_time::numeric, 2) AS total_exec_time,
       calls,
       ROUND(mean_exec_time::numeric, 2) AS mean,
       query
  FROM pg_stat_statements
 ORDER BY total_exec_time DESC
 LIMIT 20;
```