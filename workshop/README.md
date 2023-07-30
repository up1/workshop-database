# List of workshops
* TODO
* TODO

## Create database and pgadmin with Docker
```
$docker compose up -d
$docker compose ps
NAME                 IMAGE               COMMAND                  SERVICE             CREATED             STATUS              PORTS
pg_container         postgres            "docker-entrypoint.s…"   db                  17 seconds ago      Up 16 seconds       0.0.0.0:5432->5432/tcp
pgadmin4_container   dpage/pgadmin4      "/entrypoint.sh"         pgadmin             17 seconds ago      Up 16 seconds       443/tcp, 0.0.0.0:5050->80/tcp
```

Go to pgadmin = http://localhost:5050/
* user=admin@admin.com
* password=root

Create server in pgadmin
* hostname=db
* database=posgres
* user=root
* password=root

Get max connection of database = 200
```
show max_connections;
```

## Create schema of database