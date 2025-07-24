# Monitoring with PostgreSQL
* PostgreSQL
* Prometheus
* PostgreSQL exporter
* Grafana
* Testing with [pgbench](https://www.postgresql.org/docs/current/pgbench.html)


## 1. Start PodtgreSQL server
```
$docker compose up -d db
$docker compose ps
$docker-compose logs -f db
```

## 2. Start testing with pgbench
```
$docker compose up -d pgbench
$docker compose ps
$docker-compose logs pgbench 
```

## 3. Iterative process
* Tweak one parameter at a time in postgresql.conf.
* Re-run docker-compose up -d && docker-compose logs pgbench

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

