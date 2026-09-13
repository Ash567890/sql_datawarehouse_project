/*
===========================================================================================
Customer Report

Purpose:
- This report consolidates key customer metrics and behaviours
Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
- total orders
- total sales
- total quantity purchased
- total products
- lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last order)
- average order value
- average monthly spend
===========================================================================================
*/
USE datawarehouse;
go

create view gold.analytic_table as 

WITH essen_f as (
select
f.order_number,
f.product_key,
c.customer_key,
c.first_name,
c.last_name,
c.birthdate,
c.gender,
f.order_date,
f.quantity,
f.price,
f.sales
from gold.fact_sales f
left join gold.dim_customer c
on f.customer_key = c.customer_key)

-- Aggregating the customer-level metrics 
, aggre_s AS (
select 
customer_key,
first_name,
last_name,
birthdate,
--DATEDIFF(Year, birthdate, GETDATE()) birth_year,
MIN(order_date) first_order,
MAX(order_date) last_order,
SUM(sales) total_sales,
COUNT(quantity) total_count,
SUM(price) total_price
from essen_f
group by customer_key,
first_name,
last_name,
birthdate)
, mid_trans as (
select 
customer_key,
CONCAT(first_name, last_name) name,
DATEDIFF(year, birthdate, GETDATE()) birth_year,
DATEDIFF(month, first_order, last_order) total_months,
DATEDIFF(month, last_order, GETDATE()) lifespan,
total_sales as sales_amount,
total_count,
total_price
from aggre_s )

select 
customer_key,
name,
birth_year,
case 
	when birth_year < 50 then 'Below 50'
	when birth_year between 50 and 60 then '50 and 60'
	when birth_year between 60 and 70 then '60 and 70'
	else 'above 70'
end age_tag,
total_months,
lifespan as recency,
sales_amount,
total_count,
total_price,
case 
	when sales_amount >= 5000 and total_months >=12 then 'VIP'
	when sales_amount <=5000 and total_months >=12 then 'Regular'
	when total_months < 12 then 'New Customer'
end segment
from mid_trans;


