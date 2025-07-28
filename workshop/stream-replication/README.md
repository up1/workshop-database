# Workshop with Stream Replication

## 1. Start Cluster

### 1.1 Start Primary server

Change permission
```
$chmod +x primary/create_pg_hba.sh
```

Run
```
$docker compose up -d primary
$docker compose ps
```

Check replication status
* 0 row !!
```
$docker compose exec -it primary bash

$psql -U postgres
$SELECT * FROM pg_stat_replication;
$SELECT client_addr, state, sync_state FROM pg_stat_replication;
```

### 1.2 Start slave server

Change permission
```
$chmod +x replica/standby.sh
```


Run
```
$docker compose up -d replica

$docker compose ps
NAME      IMAGE         COMMAND                  SERVICE   CREATED          STATUS         PORTS
primary   postgres:17   "docker-entrypoint.s…"   primary   2 minutes ago    Up 2 minutes   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
replica   postgres:17   "docker-entrypoint.s…"   replica   24 seconds ago   Up 5 seconds   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
```

Try to Check replication in Primary status again !!
* 1 row
```
$docker compose exec -it primary bash

$psql -U postgres
$SELECT * FROM pg_stat_replication;
$SELECT client_addr, state, sync_state FROM pg_stat_replication;
```

Check on replica
```
$docker compose exec -it replica bash

$psql -U postgres

$SELECT pg_is_in_recovery();
pg_is_in_recovery 
-------------------
 t
(1 row)
```
