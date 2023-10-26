create table customers (
 customer_id     bigint constraint cust_pk primary key,
 customer_name   text   constraint cust_uk unique
);

create table orders (
 order_id bigint primary key,
 customer_id bigint references customers,
 order_date date,
 order_amount decimal
);
