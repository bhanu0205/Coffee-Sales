create database coffee_shopsales;
select*from css;
							-- Data Cleaning --
-- changing the format of transaction date
update css set transaction_date = str_to_date(transaction_date, '%d-%m-%Y');
-- changing the data type of transaction date
alter table css modify column transaction_date date;
-- changing the format of transaction time
update css set transaction_time = str_to_date(transaction_time, '%H:%i:%s');
-- changing the data type of transaction time
alter table css modify column transaction_time time;
-- changing column name
alter table css rename column ï»¿transaction_id to transaction_id ;

                               -- KPIs --
-- Total sales for each respective month
select (round(sum(unit_price * transaction_qty)))as total_sales,
monthname(transaction_date) as `Month Name`
from css
group by monthname(transaction_date);

-- MOM increase or decrease in sales
select *, coalesce((((total_sales- lag(total_sales,1) over (order by month_no))/lag(total_sales,1) over (order by month_no))*100),0) as MOM from
(select month(transaction_date) as month_no,(round(sum(unit_price * transaction_qty)))as total_sales
from css group by month_no order by month_no) dt;

-- Difference between number of sales between months
select *, coalesce(total_sales-lag(total_sales,1) over (order by month_no),0) as difference from
(select month(transaction_date) as month_no,(round(sum(unit_price * transaction_qty)))as total_sales
from css group by month_no order by month_no) dt;
  
--  Total number of orders for each respective month
select monthname(transaction_date) as month_name, count(transaction_id) as total_orders
from css
group by month_name;

-- MOM increase or decrease in number of orders
select *, coalesce((((total_orders- lag(total_orders,1) over (order by month_no))/lag(total_orders,1) over (order by month_no))*100),0) as MOM from
(select month(transaction_date) as month_no, count(transaction_id) as total_orders
from css group by month_no) dt;

-- Difference between number of orders between months
select *, coalesce(total_orders- lag(total_orders,1) over (order by month_no),0) as difference from
(select month(transaction_date) as month_no, count(transaction_id) as total_orders
from css group by month_no) dt;

--  Total number of Quantities sold for each respective month
select monthname(transaction_date) as month_name, sum(transaction_qty) as total_quantity
from css
group by month_name;

-- MOM increase or decrease in number of quantities sold
select *, coalesce((((total_quantity- lag(total_quantity,1) over (order by month_no))/lag(total_quantity,1) over (order by month_no))*100),0) as MOM from
(select month(transaction_date) as month_no, sum(transaction_qty) as total_quantity
from css group by month_no) dt;

-- Difference between number of orders between months
select *, coalesce(total_quantity- lag(total_quantity,1) over (order by month_no),0) as difference from
(select month(transaction_date) as month_no, sum(transaction_qty) as total_quantity
from css group by month_no) dt;

-- Total sales, Quantity sold, orders of any day
DELIMITER //
create procedure anydayinfo
( in trans_date date)
begin
select (round(sum(unit_price * transaction_qty)))as total_sales,
sum(transaction_qty) as total_qty_sold,
count(transaction_id) as total_orders
from css
where transaction_date = trans_date;
end //
DELIMITER ;
drop procedure anydayinfo;

CALL anydayinfo('2023-05-18')

-- sales on weekends and weekdays
DELIMITER //
create procedure we_or_wd
( in no_of_month int)
begin
select 
   case when DAYOFWEEK(transaction_date) in (1,7) then 'Weekends'
   else 'Weekdays'
   end as day_type,
   (round(sum(unit_price * transaction_qty)))as total_sales
from css
where month(transaction_date) = no_of_month
group by day_type;
end //
DELIMITER ;
drop procedure we_or_wd;
call we_or_wd (5);

-- sales based on store location
select store_location, (round(sum(unit_price * transaction_qty)))as total_sales 
from css
where month(transaction_date)
group by store_location;

-- Daily sales analysis with average line
select round(avg(total_sales)) as avg_sales
from
(select (round(sum(unit_price * transaction_qty)))as total_sales from css
where month(transaction_date) = 5
group by transaction_date)dt;

-- Daily Sales for month selected
DELIMITER //
Create procedure daily_sales_status(in n int)
begin
select day_of_month,
case
   when total_sales>avg_sales then 'Above Average'
   when total_sales<avg_sales then 'Below Average'
   else 'Average'
end as sales_status, total_sales from
(select day(transaction_date) as day_of_month,
(round(sum(unit_price * transaction_qty)))as total_sales,
avg(sum(unit_price * transaction_qty))over ()as avg_sales 
from css
where month(transaction_date)= n
group by day(transaction_date))dt
order by day_of_month;
end //
DELIMITER ;

call daily_sales_status(5);

-- Sales Analysis based on Product Category
select product_category,round(sum(unit_price * transaction_qty))as total_sales
from css
where month(transaction_date)=5
group by product_category
order by total_sales desc;

-- Top 10 Products by sales
select product_type, round(sum(unit_price * transaction_qty))as total_sales
from css
where month(transaction_date) = 5 and product_category = 'coffee'
group by product_type
order by total_sales desc
limit 10;

-- Sales of particular day and hour
DELIMITER //
Create procedure sales_analysis_days_hours(in m int, d int, h int)
begin
select (round(sum(unit_price * transaction_qty)))as total_sales,
sum(transaction_qty) as total_qty_sold,
count(transaction_id) as total_orders
from css
where month(transaction_date)= m
and dayofweek(transaction_date)= d
and hour(transaction_time) = h;
end //
DELIMITER ;

call sales_analysis_days_hours(5,1,14);

-- Sales of hours of month
select hour(transaction_time), 
(round(sum(unit_price * transaction_qty)))as total_sales
from css
where month(transaction_date)= 5
group by hour(transaction_time)
order by hour(transaction_time);

-- SALES FROM MONDAY TO SUNDAY FOR SELECTED MONTH
DELIMITER //
Create procedure m_to_s_sales(in n int)
begin
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    css
WHERE 
    MONTH(transaction_date) = n
GROUP BY Day_of_Week;
end //
DELIMITER ;

call m_to_s_sales(5);