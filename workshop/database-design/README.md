# Database design workshop
* RDBMS with PostgreSQL
    * Normalization vs De-normalization
    * Materialized Views
    * Partitioning
    * Sharding
    * Data Housekeeping

## 0. Start PostgreSQL database
```
$docker compose up -d
$docker compose ps
```

Access to pgAdmin 
* http://localhost:8080/
  * user=admin@example.com
  * password=admin
* Add new server
  * name=Demo01, 
  * host=db
  * port=5432
  * user=postgres
  * password=postgres

## 1. Normalization vs De-normalization
* When denormalization helps (reporting, read-heavy workloads)
* Trade-offs: joins & consistency vs. write amplification & storage