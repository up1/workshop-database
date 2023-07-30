# Workshop with joining in PostgreSQL

## Inner join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
INNER JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

## Left join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
LEFT JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

## Right join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
RIGHT JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

## Full outer join
```
SELECT *
FROM tbl1
FULL OUTER JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

## Self-join
```
```