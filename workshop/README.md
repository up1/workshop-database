# List of workshops
* Create tables
* [Join](joins.md)
* [Self-join](self-join.md)

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

## Design and Create schema of tables
* Open file `books/create_table.sql`
  * category
  * author
  * publisher
  * book
  * book_category
  * book_author

[Convert a SQL file to DBML](https://dbml.dbdiagram.io/cli/#convert-a-sql-file-to-dbml)
```
$cd books
$npm install -g @dbml/cli
$sql2dbml --postgres create_tables.sql -o books.dbml
```

## Add sample data
* Open file `books/data.sql`
  * category
  * author
  * publisher
  * book
  * book_category
  * book_author

## Generate test data (more)
```
INSERT INTO book (isbn, title, publication_date, rating)
SELECT SUBSTR(MD5(RANDOM()::TEXT), 0, 14), 
       MD5(RANDOM()::TEXT), 
       DATE '2023-08-01' + CAST(RANDOM() * (DATE '2023-08-01' - DATE '2023-08-01') AS INT),
       ROUND((1 + RANDOM() * 4)::numeric, 3)
  FROM generate_series(1, 100000);
```