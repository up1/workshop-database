# Workshop with joining in PostgreSQL

## SQL for Join in PostgreSQL
Inner join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
INNER JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

Left join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
LEFT JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

Right join
```
SELECT tbl1.col1, tbl2.col2...
FROM tbl1
RIGHT JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

Full outer join
```
SELECT *
FROM tbl1
FULL OUTER JOIN tbl2
ON tbl1.field_name = tbl2.field_name;
```

## Join workshop

### Step 1 :: Create table and data
* basket_a
* basket_b
```
CREATE TABLE basket_a (
    a INT PRIMARY KEY,
    fruit_a VARCHAR (100) NOT NULL
);

CREATE TABLE basket_b (
    b INT PRIMARY KEY,
    fruit_b VARCHAR (100) NOT NULL
);

INSERT INTO basket_a (a, fruit_a)
VALUES
    (1, 'Apple'),
    (2, 'Orange'),
    (3, 'Banana'),
    (4, 'Cucumber');

INSERT INTO basket_b (b, fruit_b)
VALUES
    (1, 'Orange'),
    (2, 'Apple'),
    (3, 'Watermelon'),
    (4, 'Pear');
```

## Step 2 :: Inner join
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
INNER JOIN basket_b
    ON fruit_a = fruit_b;
```

## Step 3 :: Left join
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
LEFT JOIN basket_b 
   ON fruit_a = fruit_b;
```

## Step 4 :: Left join (only left)
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
LEFT JOIN basket_b 
    ON fruit_a = fruit_b
WHERE b IS NULL;
```

## Step 5 :: Right join
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
RIGHT JOIN basket_b ON fruit_a = fruit_b;
```

## Step 6 :: Right join (only right)
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
RIGHT JOIN basket_b 
   ON fruit_a = fruit_b
WHERE a IS NULL;
```

## Step 7 :: Full outer join
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
FULL OUTER JOIN basket_b 
    ON fruit_a = fruit_b;
```

## Step 8 :: Full outer join (unique rows to both tables)
```
SELECT
    a,
    fruit_a,
    b,
    fruit_b
FROM
    basket_a
FULL JOIN basket_b 
   ON fruit_a = fruit_b
WHERE a IS NULL OR b IS NULL;
```
