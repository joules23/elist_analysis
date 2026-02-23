-- Earliest and most recent order dates
select min(purchase_ts) as earliest_order, 
  max(purchase_ts) as latest_order
from core.orders;


-- Average order value for purchases made in USD and AOV for purchases in USD in 2019
select avg(usd_price) as usd_aov
from core.orders
WHERE currency = 'USD' and
extract(year from purchase_ts)= 2019


-- ID, loyalty program status, and account creation date for customers who made an account on desktop or mobile.
select id as customer_id, 
  loyalty_program as is_loyalty_customer, 
  created_on as account_created_on
from core.customers
where account_creation_method = 'desktop' or account_creation_method ='mobile';

select distinct account_creation_method from core.customers 


-- List of unique products that were sold in AUD on website, sorted alphabetically
select distinct product_name
from core.orders
WHERE currency = 'AUD'
and purchase_platform= 'website'
ORDER BY 1 ASC; 


-- Top 10 countries in the North American region, in descending order.
select *
from core.geo_lookup 
WHERE region = 'NA'
ORDER BY 1 DESC
limit 10;

-- Total number of orders by shipping month, sorted from most recent to oldest
select date_trunc(ship_ts, month) as month,
  count(distinct order_id) as order_count
from elistcore.core.order_status
group by 1
order by 1 DESC;

-- Average order value by year rounded to 2 decimals
select extract(year from purchase_ts) as year,
  round(avg(usd_price),2) as aov
from elistcore.core.orders
group by 1
order by 1 DESC;

-- Adding a helper column to sort transactions with a refund or not.
select
  case when refund_ts is not null then 1 else 0 end as is_refund
from elistcore.core.order_status
limit 20;

-- Product IDs and product names of all Apple products.
select distinct product_name
from elistcore.core.orders;

select distinct product_id,
  product_name
from elistcore.core.orders
where product_name like 'Apple%'
or product_name like 'Macbook%';

select distinct product_id,
  product_name
from elistcore.core.orders
where product_name in ('Apple Airpods Headphones','Apple iPhone','Macbook Air Laptop');


-- Time to ship in days for each order with existing columns.
select *,
  date_diff(ship_ts, purchase_ts, day) as days_to_ship
from elistcore.core.order_status;

-- Refund rate per year, expressed as a percent 
select extract(year from purchase_ts) as year,
  round(avg( case when refund_ts is not null then 1 else 0 end)*100,2) as refund_rate
from core.order_status
group by 1
order by 1;


-- Total number of orders per year for each product sorted by months. 
select distinct product_name
from core.orders;

select date_trunc(purchase_ts, month) as month,
  case when product_name = '27in"" 4K gaming monitor'
  then '27in 4K gaming monitor'
  else product_name 
  end as product_name_cleaned,
count (distinct id) as order_count
from core.orders
group by 1,2
order by 1,2 ASC;


-- Average order value per year for products that are either laptops or headphones
select extract(year from purchase_ts) as year,
  round(avg(usd_price),2) as aov
from core.orders
where lower(product_name) like '%laptop%' 
  or lower(product_name) like '%headphones%'
group by 1
order by 1;

-- Order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years
select date_trunc(purchase_ts, quarter) as quarter,   
  count (orders.id) as order_count,
  round(sum(orders.usd_price),2) as sales,
  round(avg(orders.usd_price),2) as aov
from core.orders
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup
  on geo_lookup.country_code= customers.country_code
where region = 'NA'
AND lower(product_name) LIKE '%macbook%'
group by 1
order by 1 DESC;

--Delivery time in days for products purchased in 2022 on the website or products purchased on mobile
select region,
  avg(date_diff(delivery_ts, order_status.purchase_ts,day)) as days_to_deliver
from core.order_status
left join core.orders
  on order_status.order_id = orders.id
left join core.customers
  on customers.id = orders.customer_id
left join core.geo_lookup
  on customers.country_code = geo_lookup.country_code
where extract(year from order_status.purchase_ts) = 2022
AND orders.purchase_platform = 'website' 
or orders.purchase_platform = 'mobile app'
group by 1
order by 2 desc;


-- Refund rate and refund count for each product overall
select distinct product_name
from core.orders;

select product_name,
case when product_name = '27in"" 4k gaming monitor' 
  then '27in 4k gaming monitor'
  else product_name end as product_cleaned,
  sum (case when refund_ts is not null then 1 else 0 end) as count_refund,
  avg(case when refund_ts is not null then 1 else 0 end) as refund_rate
from core.orders
left join core.order_status
  ON orders.id = order_status.order_id
group by 1
order by 3 DESC;


-- Most popular product within each region
with order_count_cte as (
  select geo_lookup.region, 
    orders.product_name, 
    case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    count (distinct orders.id) as order_count
  from core.orders 
  left join core.customers
    on customers.id = orders.customer_id
  left join core.geo_lookup
    on geo_lookup.country_code = customers.country_code
  group by 1,2),

  ranked_orders as (
    select * ,
    row_number() over (partition by region order by order_count desc) as ranking
  from order_count_cte)

  select *
  from ranked_orders
  where ranking =1;


--Difference of time to make a purchase between loyalty customers vs. non-loyalty customers
select customers.loyalty_program, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, day)),2) as time_to_purchase_days, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, month)),2) as time_to_purchase_months, 
from core.orders
left join core.customers
  on customers.id = orders.customer_id
left join core.order_status 
  on order_status.order_id = orders.id
group by 1;


-- Order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years
select date_trunc(purchase_ts, quarter) as quarter,
  count(orders.id) as order_count,
  round(sum(orders.usd_price),2) as sales,
  round(avg(orders.usd_price),2) as AOV
from core.orders
left join core.customers
  ON orders.customer_id = customers.id
left join core.geo_lookup
  ON customers.country_code = geo_lookup.country_code
WHERE region = 'NA' 
AND lower(product_name) like '%macbook%'
group by 1
order by 1;


-- Region with the average highest time to deliver (in days) for products purchased in 2022 on the website or products purchased on mobile in any year.
select region, 
  round(avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)),2) as delivery_time
from core.order_status
left join core.orders
  ON orders.id = order_status.order_id
left join core.customers
  ON orders.customer_id = customers.id
left join core.geo_lookup
  ON customers.country_code = geo_lookup.country_code
where orders.purchase_platform = 'website' AND 
extract(year from order_status.purchase_ts) = 2022
OR orders.purchase_platform = 'mobile app'
group by 1
order by delivery_time DESC;

--Delivery time in days for website purchases made in 2022 or Samsung purchases made in 2021.
select region, 
  round(avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, week)),2) as delivery_time
from core.order_status
left join core.orders
  ON orders.id = order_status.order_id
left join core.customers
  ON orders.customer_id = customers.id
left join core.geo_lookup
  ON customers.country_code = geo_lookup.country_code
where orders.purchase_platform = 'website' AND 
extract(year from order_status.purchase_ts) = 2022
Or orders.product_name LIKE 'Samsung%'
AND extract(year from order_status.purchase_ts) = 2021
group by 1
order by delivery_time DESC;





















