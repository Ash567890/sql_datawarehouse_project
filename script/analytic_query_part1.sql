use datawarehouse;
go


select * from gold.fact_sales;

-- customer_key as a foreign key in fact_sales and an unique indentifier for dim_customer table 

-- product_key as a foreign key in the fact_sales and an unique indentifier for dim_product table


/*
Analyse sales performance over time 
*/

select year(order_date), SUM(sales)
from gold.fact_sales
where order_date is not null
group by YEAR(order_date);


-- We use DATETRUNC for analysing the details over months

select DATETRUNC(month, order_date), sum(sales) 
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
order by 1;

-- The problem with the FORMAT function is that SQL didn't group the data 

select FORMAT(order_date,'yyyy-MMM-dd'), sum(sales) 
from gold.fact_sales
where order_date is not null
group by FORMAT(order_date,'yyyy-MMM-dd') ---- No need to add dd(date) if you want to aggregate the data 
order by 1;

select FORMAT(order_date,'yyyy-MMM'), sum(sales) 
from gold.fact_sales
where order_date is not null
group by FORMAT(order_date,'yyyy-MMM') 
order by 1;

/*
Analyse sales, quantity, and customer count performance over time
*/

select year(order_date), SUM(sales) sales_year,
SUM(quantity) sales_quantity, count(distinct customer_key) count_customer
from gold.fact_sales
where order_date is not null
group by YEAR(order_date);

-- only month analysis 

select YEAR(order_date), month(order_date) over_month, SUM(sales) sales
from gold.fact_sales
where order_date is not null
group by YEAR(order_date) ,month(order_date)
order by 1;

/*
Calculate the total sum per month
and the running total of sales over time
*/
select *, SUM(sales) over (partition by Year(over_month) order by over_month) runing_total
from (
select DATETRUNC(month, order_date) over_month, sum(sales) sales
from gold.fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)
) t

/*
Analyse the yearly performance of products by comparing each product's sales 
to both its average sales performance and previous year's sales
*/

with sales_per as (
select 
	Year(f.order_date) date_year, 
	d.product_name product_name,
	SUM(f.sales) sales 
from gold.fact_sales f
left join gold.dim_product d
on f.product_key = d.product_key
where Year(f.order_date) is not null
group by YEAR(f.order_date), d.product_name
)
select 
date_year, product_name, sales,
AVG(sales) over (partition by product_name) avg_sales,
case 
	when sales - AVG(sales) over (partition by product_name) > 0 then 'above'
	when sales - AVG(sales) over (partition by product_name) < 0 then 'below'
	else 'equal'
end as diff_avg_tag,
lag(sales) over (partition by product_name order by date_year) lag_sales,
case	
	when sales - lag(sales) over (partition by product_name order by date_year) > 0 then 'improved'
	when sales - lag(sales) over (partition by product_name order by date_year) < 0 then 'decreased'
	else 'no change'
end as change_over_year
from sales_per


/*
Part-to-whole Analysis

-- Which category contributes the most overall sales

(category sales/total category sales) * 100

*/

with cat_sales_con as (
select category as category, sum(sales) as cat_sales from gold.fact_sales f
left join gold.dim_product d
on f.product_key = d.product_key
group by category)

select category, cat_sales,
sum(cat_sales) over () total_sales,
CONCAT(ROUND((cast(cat_sales as float)/ sum(cat_sales) over ())*100,2),'%') percentage_con
from cat_sales_con
order by cat_sales desc

/*
Segment products into cost ranges and
count how many products fall into each segment.
*/
-- Segment products into cost ranges and count how many products fall into each segment.

select count(product_key) count_key, cost_range
from (
select d.product_key product_key, d.product_cost,
case 
	when d.product_cost < 100 then 'Below 100'
	when d.product_cost between 100 and 500 then '100-500'
	when d.product_cost between 500 and 1000 then '500-1000'
	else 'Above'
end cost_range
from gold.fact_sales f
left join gold.dim_product d
on f.product_key = d.product_key) t
group by cost_range
order by count_key desc

/* 

Group customers into three segments based on their spending behaviour:
- VIP: Customers with at least 12 months of history and spending more than €5,000.
- Regular: Customers with at least 12 months of history but spending €5,000 or less.
- New: Customers with a lifespan of less than 12 months.
And find the total number of customers in each group

*/
with spending as (
select 
	d.customer_key customer_key, 
	min(f.order_date) first_order, 
	max(f.order_date) last_order,
	DATEDIFF(MONTH,min(f.order_date),max(f.order_date)) Total_months,
	sum(f.sales) sales_amount
from gold.fact_sales f
left join gold.dim_customer d
on f.customer_key = d.customer_key
group by d.customer_key)

select count(customer_key) count_customer, segment from (
select *,
case 
	when sales_amount >= 5000 and Total_months >=12 then 'VIP'
	when sales_amount <=5000 and Total_months >=12 then 'Regular'
	when Total_months < 12 then 'New Customer'
end segment
from spending) t
where segment is not null
group by segment
