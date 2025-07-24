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


