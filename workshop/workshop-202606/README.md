# Workshop :: Database design with PostgreSQL

## Topics
* Database design
* Normalization vs Denormalization
* PostgreSQL features for database design
* Indexing strategies
* Query optimization
* Best practices for database design

## Use cases
* Slow query performance and how to optimize it
* Connection pooling issues and how to resolve them and scale the database
* Data caching to reduce database load and improve performance
* Separate read and write operations for better performance
* Database partitioning for large datasets

## Start Database with Docker
```bash
$docker compose up -d
$docker compose ps
```

Access to database
* password=pass

```bash
$docker compose exec db psql -U user -d orders
```

List of commands
* \l : list databases
* \c : connect to database
* \dt : list tables
* \d : describe table
* \q : quit
