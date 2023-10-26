# Workshop :: Improve performance

## Step 1 :: Create tables
```
create table customers (
 customer_id     bigserial constraint cust_pk primary key,
 customer_name   text   constraint cust_uk unique
);

create table orders (
 order_id bigserial primary key,
 customer_id bigint references customers,
 order_date date,
 order_amount decimal
);
```

## Step 2 :: Generate data for testing

Customer table
```
insert into customers(
  customer_name
)
select
  SUBSTR(MD5(RANDOM()::TEXT), 0, 14)
from generate_series(1, 10000) i;
```


Order table
```
insert into orders(
  customer_id,
  order_date,
  order_amount
)
select
  round((random() * 9000) + 1),
  DATE '2010-01-01' + CAST(RANDOM() * (DATE '2024-01-01' - DATE '2010-01-01') AS INT),
  round(random() * 10000000)
from generate_series(1, 600000) i;
```

## Step 3 :: Query data from condition !!
* Get amount of orders by customer name in 2 years
```
select sum(ord.order_amount)
from customers cus join orders ord on cus.customer_id=ord.customer_id
where cus.customer_name='George Clooney'
and order_date > now() - interval '2 years';
```

## Step 4 :: Try to explain and improve performance ...
