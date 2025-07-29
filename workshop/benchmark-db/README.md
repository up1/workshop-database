# Benchmark :: PostgreSQL
* [pgbench](https://www.postgresql.org/docs/current/pgbench.html)
* [benchbase](https://github.com/cmu-db/benchbase)
  * Multi-DBMS SQL Benchmarking Framework via JDBC

## Working with BenchBase
* Required [JDK 23+](https://www.oracle.com/java/technologies/javase/jdk23-archive-downloads.html)


Build
```
$git clone --depth 1 https://github.com/cmu-db/benchbase.git
$cd benchbase
$./mvnw clean package -P postgres -DskipTests
```

Go to folder `target`
```
$cd target
$tar xvzf benchbase-postgres.tgz
$cd benchbase-postgres
```

Run with config
* config/postgres/sample_tpcc_config.xml
```
$java -jar benchbase.jar -b tpcc -c config/postgres/sample_tpcc_config.xml --create=true --load=true --execute=true
```

## Try to improve performance
* Tuning postgresql parameters

