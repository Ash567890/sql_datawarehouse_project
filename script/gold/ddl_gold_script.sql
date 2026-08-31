/*
Creating SQL script for gold layer
In which we analyse the data for data analytics.
We create a view for the data analyst 


*/
use datawarehouse;
go


--================================================================================
create view gold.dim_customer as
select 
	row_number() over (order by c.cst_id) as customer_key,
	c.cst_id as customer_id, 
	c.cst_key as customer_number, 
	c.cst_firstname as first_name, 
	c.cst_lastname as last_name, 
	CASE 
		WHEN c.cst_gndr = 'N/A' THEN Coalesce(e.gen, 'N/A')
		else c.cst_gndr
	END gender,
	e.bdate as birthdate,
	c.cst_marital_status as marital_status, 
	l.cntry as country,
	c.cst_create_date as create_date
from silver.crm_cust_info c
left join silver.erp_cust_az12 e
on c.cst_key = e.cid
left join silver.erp_loc_a101 l
on c.cst_key = l.cid;

--================================================================================
  
create view gold.dim_product as 
select 
	ROW_NUMBER() over (order by c.prd_start_dt, c.prd_key) as product_key,
	c.prd_id as product_id, 
	c.prd_key as product_number,
	c.cat_id as category_id,  
	e.cat as category, 
	e.subcat as subcategory,
	c.prd_nm as product_name, 
	e.maintenance,
	c.prd_line as product_line,
	c.prd_cost as product_cost,  
	c.prd_start_dt as start_date
from silver.crm_prd_info c
left join silver.erp_px_cat_g1v2 e
on c.cat_id = e.id
where c.prd_end_dt is null -- filtering historical data

------------------------------------------------------------------------------------


create view gold.fact_sales as 
select 
	s.sls_ord_num as order_number,
	gp.product_key,
	gc.customer_key,
	s.sls_order_dt order_date,
	s.sls_ship_dt as ship_date,
	s.sls_due_dt as due_date,
	s.sls_price as price,
	s.sls_quantity as quantity,
	s.sls_sales as sales
from silver.crm_sales_details s
left join gold.dim_product gp
on s.sls_prd_key = gp.product_number
left join gold.dim_customer gc
on s.sls_cust_id = gc.customer_id
