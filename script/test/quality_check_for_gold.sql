/*
Quality check for gold layer
Have a look at this code for better understanding 

*/

use datawarehouse;
go

select cst_id, count(*) from (
select 
  c.cst_id, 
  c.cst_key, 
  c.cst_firstname, 
  c.cst_lastname, 
  CASE 
  	WHEN c.cst_gndr = 'N/A' THEN ISNULL(e.gen, 'N/A')
  	else c.cst_gndr
  END gender,
  e.bdate,
  c.cst_marital_status, 
  l.cntry,
  c.cst_create_date
from silver.crm_cust_info c
left join silver.erp_cust_az12 e
on c.cst_key = e.cid
left join silver.erp_loc_a101 l
on c.cst_key = l.cid) t
group by cst_id
having count(*) > 1
--------------------------------------------------------------------

select distinct 
c.cst_gndr,
e.gen,
CASE 
	WHEN c.cst_gndr = 'N/A' THEN ISNULL(e.gen, 'N/A')
	else c.cst_gndr
END gender
from silver.crm_cust_info c
left join silver.erp_cust_az12 e
on c.cst_key = e.cid
left join silver.erp_loc_a101 l
on c.cst_key = l.cid
order by 1, 2;
----------------------------------------------------------
-- quality check for gold layer

select distinct gender from gold.dim_customer;

----------------------------------------------------------------------------------------

--checking quality of product in gold layer

select distinct prd_key, count(*) from (
select 
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
where c.prd_end_dt is null) t 
group by prd_key
having count(*) > 1;

------------------------------------------------------------
select * from gold.fact_sales gs
left join gold.dim_customer gc
on gs.customer_key = gc.customer_key
where gs.customer_key is null
-------------------------------------------------------------------------------------------
--Checking Foreign Key integration 

select * from gold.fact_sales gs
left join gold.dim_product gp
on gs.product_key = gp.product_key
where gs.product_key is null

select * from gold.fact_sales gs
left join gold.dim_customer gc
on gs.customer_key = gc.customer_key
where gc.customer_key is null
