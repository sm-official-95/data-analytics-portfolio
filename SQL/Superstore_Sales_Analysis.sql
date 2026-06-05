-- ================================================================
-- Project  : Superstore Sales Analysis
-- Tool     : MySQL Workbench
-- Dataset  : Sample Superstore (Kaggle)
-- Author   : Suvodip Mistry
-- Date     : May 2026
-- ================================================================

create database superstore_sales_analysis;

use superstore_sales_analysis;

RENAME TABLE `Sample - Superstore` TO superstore;

select *
from superstore;


-- (1) Total sales by region to identify high-revenue markets for marketing focus.
select 
	region,
    round(sum(sales),2) as total_sales
from superstore
group by region
order by round(sum(sales),2) desc;


-- (2) Top 10 most profitable products to prioritize for sales promotions.
select 
	`Product Name`,
    round(sum(profit), 2) as total_profit
from superstore
group by `Product Name`
order by total_profit desc
limit 10;


-- (3) Analyzing profit by customer segment to evaluate overall segment performance.
select 
  Segment,
  round(sum(profit), 2) as total_profit
from superstore 
group by Segment
having total_profit<0; 


-- (4) Flagging loss-making orders with discounts to investigate pricing strategy.
select 
	`Order ID`,
    `Product Name`,
    Discount,
    round(Profit, 2) as profit
from superstore
where Profit<0 and Discount>0;


-- (5) Categorizing orders by profit performance for quick management overview.
select 
	`Order ID`,
    `Product Name`,
    round(Profit, 2) as pofit,
    case
		when Profit> 500 then '`High Profit`'
        when Profit> 100 then '`Medium Profit`'
        when Profit> 0 then '`Low Profit`'
        else 'Loss`'
	end as '`Profit wise Category`'
from superstore;


-- (6) Finding orders with above-average sales to identify outstanding performances.
with sales_analytics as(
			select 
				`Order ID`,
                `Product Name`,
                Sales,
                round(avg(Sales) over(), 2) as average_sales
			from Superstore
)
select *
from sales_analytics
where Sales> average_sales;


-- (7) Identifying most valuable customers based on total orders and sales generated.
/*Simple Version*/
select 
`Customer Name`,
count(distinct `Order ID`) as `Order No`,
round(sum(Sales), 2) as `Total Sales`
from superstore
group by `Customer Name`, `Customer ID`
order by `Total Sales` desc;

/* CTE Version*/
with superstore_analytics as(
	select 
		`Customer ID`,
        count(distinct `Order ID`) as order_numbers,
        round(sum(sales),2) as total_sales
	from Superstore
    group by `Customer ID`
)
select distinct
	S.`Customer Name`,
    SA.order_numbers,
    SA.total_sales
from Superstore S
join superstore_analytics SA
	on S.`Customer ID`= SA.`Customer ID`
order by total_sales desc;


-- (8) Analyzing impact of discount ranges on profit to optimize pricing strategy.
select
	case
		when Discount= 0 then 'No Discount'
        when Discount> 0 and Discount<= 0.3 then 'Low Discount'
        when Discount> 0.3 and Discount <= 0.5 then 'Medium Discount'
        else 'High Discount'
	end as 'Discount Band',
count(`Order ID`) as 'Order No',
round(sum(Profit), 2) as 'Total Profit'
from superstore
group by `Discount Band`
order by `Total Profit` desc;    


-- (9) Ranking products within each category by total sales to identify top performers.
with superstore_analytics as(
  select
    category,
    `Product Name`,
    round(sum(sales), 2) as total_sales
  from superstore
  group by category, `Product Name`
)
select 
  category,
  `Product Name`,
  total_sales,
  rank() over(
    partition by category
    order by total_sales desc
    ) as ranked_products
from superstore_analytics ;


-- (10) Analyzing month-over-month sales trend to identify growth and decline patterns.
DESC superstore;
with superstore_analytics as(
	select
		year(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) as Year,
        month(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) as Month,
        round(sum(Sales), 2) as Total_Sales
	from superstore
    group by year(STR_TO_DATE(`Order Date`, '%m/%d/%Y')),
        month(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))
)
select
	Year,
    Month,
    Total_Sales,
    lag(round(Total_Sales, 2)) over(
		order by Year asc, Month asc
        ) as pevious_sales,
	Total_Sales-lag(round(Total_Sales),2) over(
		order by Year asc, Month asc
        ) as MoM_Change
from superstore_analytics;


-- (11) Ranking states by total profit using DENSE_RANK to handle ties without gaps.
with profit_analytics as(
	select
		State,
        round(sum(Profit),2) as Total_Profit
	from superstore
    group by State
)
select
	State,
    Total_Profit,
    dense_rank() over(
		order by Total_Profit desc
        ) as Ranked_Profit
from profit_analytics
order by Ranked_Profit asc;


-- (12) Assigning unique row numbers to orders within each region sorted by sales.
select 
	Region,
    `Order ID`,
    `Customer Name`,
    Sales,
    row_number() over(
		partition by Region
        order by Sales desc
        ) as Row_Numbered_Order
from superstore;


-- (13) Calculating cumulative running total of sales month by month to track growth.
with superstore_analytics as(
	select
		year(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) as Year,
        month(STR_TO_DATE(`Order Date`, '%m/%d/%Y')) as Month,
        round(sum(Sales), 2) as Total_Sales
	from superstore
    group by
		year(STR_TO_DATE(`Order Date`, '%m/%d/%Y')),
        month(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))
)
select
	Year,
    Month,
    Total_Sales,
    round(sum(Total_Sales) over(
		order by Year, Month asc
        rows between unbounded preceding and current row
        ), 2) as Running_Total_Sales
from superstore_analytics;


-- (14) Complete category performance summary with sales, profit, margin and ranking.
with profit_margin_analytics as(
	select
		category,
        round(sum(sales), 2) as Total_Sales,
        round(sum(profit), 2) as Total_Profit,
        round((sum(profit)/sum(sales))*100, 2) as Profit_Margin_Percentage
	from superstore
    group by category
) 
select 
	Category,
	Total_Sales,
    Total_Profit,
    Profit_Margin_Percentage,
    rank() over(
		order by Total_Profit desc
        ) as Category_Rank
from profit_margin_analytics
order by Category_Rank;


-- (15) Finding top 3 profitable products per category and region for targeted decisions.
with profit_summarisation as(
  select
    Region,
    Category,
    `Product Name`,
    round(sum(profit), 2) as Total_Profit,
    dense_rank() over(
      partition  by Category, Region
      order by sum(Profit) desc
      ) Ranked_Products
  from superstore
  group by 
	Category,
	Region,
	`Product Name`
)
select *
from Profit_Summarisation 
where Ranked_Products<=3;