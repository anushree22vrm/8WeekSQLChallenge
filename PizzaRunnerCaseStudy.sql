CREATE DATABASE pizza_runner;
USE pizza_runner

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME2
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

											-- DATA CLEANING --
-- Treating null values

select * from customer_orders
update customer_orders
set exclusions = nullif(exclusions,'null'),
    extras = nullif(extras,'null'),

update customer_orders
set exclusions = nullif(exclusions,''), extras = nullif(extras,'')

select * from runner_orders
update runner_orders
set pickup_time = nullif(pickup_time,'null'),
    distance = nullif(distance,'null'),
	duration = nullif(duration,'null'),
	cancellation = nullif(cancellation,'null')

update runner_orders
set distance = replace(distance,'km','')
    
update runner_orders
set	duration = replace(replace(replace(duration,'minutes',''),'mins',''),'minute','')

-- Correcting data types
alter table runner_orders
alter column pickup_time datetime

alter table pizza_names
alter column pizza_name varchar(20)

alter table pizza_toppings
alter column topping_name varchar(20)

alter table pizza_recipes
alter column toppings varchar(40)

										  -- Case Study Questions --

-- A. Pizza Metrics


-- How many pizzas were ordered?                           

select count(*) as pizzas_ordered
from customer_orders c
join 
runner_orders ro
on c.order_id = ro.order_id
where cancellation != 'Restaurant Cancellation' or cancellation != 'Customer Cancellation'

-- How many unique customer orders were made?
select count(distinct order_id) as unique_customer_orders
from customer_orders

-- How many successful orders were delivered by each runner?
select * from runner_orders

select runner_id, count(*) as successful_orders
from runner_orders
where cancellation is null or (cancellation != 'Restaurant Cancellation' and cancellation != 'Customer Cancellation')
group by runner_id

-- How many of each type of pizza was delivered?
select * from customer_orders
select * from runner_orders

select c.pizza_id,count(*) as delivered_count
from customer_orders c
join runner_orders ro
on c.order_id = ro.order_id
where ro.cancellation is null or (ro.cancellation != 'Restaurant Cancellation' and ro.cancellation != 'Customer Cancellation')
group by c.pizza_id

-- How many Vegetarian and Meatlovers were ordered by each customer?
select p.pizza_id,p.pizza_name,count(*) as counts
from customer_orders c
join
pizza_names p
on c.pizza_id = p.pizza_id
group by p.pizza_id, p.pizza_name

-- What was the maximum number of pizzas delivered in a single order?
with deliveries as
(
  select c.order_id,count(*) as number_of_deliveries
  from customer_orders c
  join runner_orders ro
  on c.order_id = ro.order_id
  where ro.cancellation is null or (ro.cancellation != 'Restaurant Cancellation' and ro.cancellation != 'Customer Cancellation')
  group by c.order_id
)
select max(number_of_deliveries) as max_delivery
from deliveries


-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

with delivered_orders as
(
 select c.order_id,c.customer_id,c.pizza_id,c.extras,c.exclusions
 from customer_orders c
 join 
 runner_orders ro
 on c.order_id = ro.order_id
 where ro.cancellation is null or ro.cancellation = ''
),

changes as
(
 select case when extras is null and exclusions is null then 'no changes'
 else 'atleast_one_change'
 end as change_or_not
 from delivered_orders
)
select sum(case when change_or_not = 'no changes' then 1 else 0 end) as pizzas_with_no_change,
       sum(case when change_or_not = 'atleast_one_change' then 1 else 0 end) as pizzas_with_change
from changes

-- How many pizzas were delivered that had both exclusions and extras?
with delivered_orders as
( 
 select c.customer_id,c.order_id,c.pizza_id,c.extras,c.exclusions
 from customer_orders c
 join runner_orders ro
 on c.order_id = ro.order_id
 where ro.cancellation is null or ro.cancellation = ''
)
 select sum(case when extras is not null and exclusions is not null then 1 else 0 end) as pizzas_with_extras_and_exclusions
 from delivered_orders
 

-- What was the total volume of pizzas ordered for each hour of the day?
select datepart(hour,order_time) as hour_of_day, count(*) as pizza_count
from customer_orders
group by datepart(hour,order_time)
order by hour_of_day

-- What was the volume of orders for each day of the week?
select datepart(weekday,order_time) as weekdays,datename(weekday,order_time) as weekday_name,count(*) as pizza_count
from customer_orders
group by datepart(weekday,order_time),datename(weekday,order_time)
order by weekdays



-- B. Runner and Customer Experience



-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select dateadd(week,datediff(week,'2021-01-01',registration_date),'2021-01-01') as week_start,count(runner_id) as counts
from runners
group by dateadd(week,datediff(week,'2021-01-01',registration_date),'2021-01-01')
order by week_start

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select ro.runner_id,avg(datediff(minute,cast(c.order_time as datetime),ro.pickup_time)) as avg_time
from runner_orders ro
join 
customer_orders c
on ro.order_id = c.order_id
where ro.pickup_time is not null
group by ro.runner_id

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

with pizza_time as (
select count(*) as pizza_count, avg(datediff(minute,c.order_time,ro.pickup_time)) as prep_time
from customer_orders c
join runner_orders ro
on c.order_id = ro.order_id
where ro.pickup_time is not null
group by c.order_id 
)

SELECT pizza_count, avg(prep_time) as avg_prep_time
from pizza_time 
group by pizza_count
order by pizza_count

-- What was the average distance travelled for each customer?
select c.customer_id,avg(try_cast(ro.distance as float)) avg_distance
from customer_orders c
join 
runner_orders ro
on c.order_id = ro.order_id
where ro.cancellation is null or ro.cancellation = '' and ro.distance is not null
group by c.customer_id

-- What was the difference between the longest and shortest delivery times for all orders?
select (max(try_cast(duration as int)) - min(try_cast(duration as int))) as delivery_time_diff
from runner_orders
where cancellation is null or cancellation = '' and distance is not null

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select order_id,runner_id,avg(try_cast(distance as float)/try_cast(duration as int)) as speed
from runner_orders
where cancellation is null and distance is not null and duration is not null
group by order_id,runner_id
order by order_id,runner_id

-- What is the successful delivery percentage for each runner?

 select runner_id,count(*) as cancel_deliveries
 from runner_orders
 where cancellation is not null and
 ( select count(*)

 select runner_id,count(*) as cancel_counts
 from runner_orders
 where cancellation is not null
 group by runner_id


 select runner_id, 100 * sum(case when cancellation is null or cancellation = '' then 1 else 0 end )/ count(*) as percentages
 from runner_orders
 group by runner_id


-- C. Ingredient Optimisation


-- What are the standard ingredients for each pizza?
with extracted_topping as 
(
	select pr.pizza_id as pizza_id, splitvalues.value as topping_id
	from pizza_recipes pr
	cross apply string_split(pr.toppings,',') as splitvalues
	group by pr.pizza_id, splitvalues.value
)

select et.pizza_id, STRING_AGG(pt.topping_name, ', ') as standard_ingredients
	from 
	extracted_topping et
	left join pizza_toppings pt
	on et.topping_id = pt.topping_id
	group by et.pizza_id
	

-- What was the most commonly added extra?
with popular_extra as
(
	select splitvalues.value as extras, count(*) as freq
	from customer_orders c
	cross apply string_split(c.extras,',') as splitvalues
	group by splitvalues.value
)
select top 1 * 
from popular_extra
order by freq desc 


-- What was the most common exclusion?

with popular_exclusion as
(
	select splitvalues.value as exclusions, count(*) as freq
	from customer_orders c
	cross apply string_split(c.exclusions,',') as splitvalues
	group by splitvalues.value
)
select top 1 * 
from popular_exclusion
order by freq desc


-- Generate an order item for each record in the customers_orders table in the format of one of the following:
--> Meat Lovers
--> Meat Lovers - Exclude Beef
--> Meat Lovers - Extra Bacon
--> Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with splitted_extras_ids as
( select c.order_id as order_id,splitextras.value as extra
  from customer_orders c
  cross apply string_split(c.extras,',') as splitextras
  group by c.order_id,splitextras.value
),
extras_result as (
select et.order_id, STRING_AGG(pt.topping_name, ', ') as extras
	from 
	splitted_extras_ids et
	left join pizza_toppings pt
	on et.extra = pt.topping_id
	group by et.order_id
),
--select * from extras_result
 splitted_exclusion_ids as
( select c.order_id as order_id,splitexclusions.value as exclusion
  from customer_orders c
  cross apply string_split(c.exclusions,',') as splitexclusions
  group by c.order_id,splitexclusions.value
),
exclusions_result as (
select et.order_id, STRING_AGG(pt.topping_name, ', ') as exclusion
	from 
	splitted_exclusion_ids et
	left join pizza_toppings pt
	on et.exclusion = pt.topping_id
	group by et.order_id
)
--select * from exclusions_result

select co.*, 
CONCAT_WS(' - ', 
pn.pizza_name, 
CASE WHEN ex.exclusion is not null THEN CONCAT('Exclude ', ex.exclusion) END,
CASE WHEN ext.extras is not null THEN CONCAT('Extra ', ext.extras) END) as summary  from 
customer_orders co
left join exclusions_result ex on ex.order_id = co.order_id
left join extras_result ext on ext.order_id = co.order_id
left join pizza_names pn on pn.pizza_id = co.pizza_id


-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with split_extras as
(
 select c.order_id, c.pizza_id, CAST(extrasplit.value as INT) as topping_id, count(*) as extra_count
 from customer_orders c
 cross apply string_split(c.extras,',') as extrasplit
 group by order_id, pizza_id, extrasplit.value
),
split_exclusions as
(
 select c.order_id, pizza_id, CAST(exclsplit.value as INT) as topping_id, count(*) as exclusion_count
 from customer_orders c
 cross apply string_split(c.exclusions,',') as exclsplit
 group by c.order_id, pizza_id, exclsplit.value
),
ingredients as
(
 select c.order_id,c.pizza_id, CAST(TRIM(splitvalues.value) AS INT) as topping_id, count(*) as ingredient_count
 from pizza_recipes pr
 cross apply string_split(pr.toppings,',') as splitvalues
 join customer_orders c
 on c.pizza_id = pr.pizza_id
 group by c.order_id, c.pizza_id, CAST(TRIM(splitvalues.value) AS INT)
),
-- ingredients + extras - exclusions. 
ing_freq as (
select i.order_id, i.pizza_id, pt.topping_name, 
(i.ingredient_count + ISNULL(ext.extra_count, 0) - ISNULL(exc.exclusion_count, 0)) as total_count
from ingredients i
left join split_extras ext on ext.order_id =  i.order_id and ext.topping_id = i.topping_id
left join split_exclusions exc on exc.order_id =  i.order_id and exc.topping_id = i.topping_id
join pizza_toppings pt on pt.topping_id = i.topping_id
)

select order_id, pizza_id, 
STRING_AGG(case 
when total_count > 1 then concat(total_count,'x ', topping_name)
when total_count = 1 then topping_name end, ',') as i_description
from ing_freq
group by order_id, pizza_id


-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with ingr_freq as
(
 select c.order_id,c.pizza_id, CAST(TRIM(splitvalues.value) AS INT) as topping_id, count(*) as ingredient_count
 from pizza_recipes pr
 cross apply string_split(pr.toppings,',') as splitvalues
 join customer_orders c
 on c.pizza_id = pr.pizza_id
 group by c.order_id, c.pizza_id, CAST(TRIM(splitvalues.value) AS INT)
)
select topping_id,sum(ingredient_count) as total_qty
from ingr_freq
group by topping_id
order by total_qty desc


-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with revenue as
(
select sum(case when pizza_id = 1 then 1 else 0 end) * 12 as revenue_meat_lovers,
sum(case when pizza_id = 2 then 1 else 0 end) *10 as revenue_vegetarian
from customer_orders c
join 
runner_orders ro
on c.order_id = ro.order_id
where ro.cancellation is null or ro.cancellation = ''
)
select (revenue_meat_lovers + revenue_vegetarian) as total_revenue
from revenue

-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese = 4 is $1 extra


with extras_cost as
(
  select c.order_id, count(*) as cheese_cost
  from customer_orders c
  cross apply string_split(c.extras, ',') as splitvalues
  where splitvalues.value = 4
  group by c.order_id
),

revenue as
(
select c.order_id,sum(case when pizza_id = 1 then 1 else 0 end) * 12 as price_nonveg,
sum(case when pizza_id = 2 then 1 else 0 end) *10 as price_veg
from customer_orders c
join 
runner_orders ro
on c.order_id = ro.order_id
where ro.cancellation is null or ro.cancellation = ''
group by c.order_id
)
select sum(r.price_nonveg+ r.price_veg+ ISNULL(e.cheese_cost, 0)) as total_revenue
from revenue r
left join extras_cost e
on r.order_id = e.order_id

 
/* The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their 
runner,how would you design an additional table for this new dataset - generate a schema for this new table
and insert your own data for ratings for each successful customer order between 1 to 5. */


select c.order_id,ro.runner_id, (RAND()*(5 - 1) + 1) as rating
into runner_ratings
from customer_orders c
join runner_orders ro
on c.order_id = ro.order_id
where cancellation is null or cancellation = '' 

update runner_ratings
set rating = cast(rating as int)

select * from runner_ratings


/* Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */

select c.customer_id,c.order_id,ro.runner_id,r.rating,c.order_time,ro.pickup_time,
(cast(ro.pickup_time as datetime) - cast(c.order_time as datetime)) as time_bw_order_and_pickup,
ro.duration,
cast(replace(distance,'km','') as float)/cast(replace(replace(replace(duration,'minutes',''),'minute',''),'mins','') as int) as speed,
count(*) as total_pizzas
from customer_orders c
join
runner_orders ro
on c.order_id = ro.order_id
join
runner_ratings r
on c.order_id = r.order_id
group by c.customer_id,c.order_id,ro.runner_id,r.rating,c.order_time,ro.pickup_time,ro.duration,ro.distance
order by order_id


--If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is
-- paid $0.30 per kilometre traveled how much money does Pizza Runner have left over after these deliveries?

with metrics as
(
select ((sum(case when pizza_id = 1 then 12 else 10 end))) as revenue,
sum(cast(replace(ro.distance,'km','') as float)) * 0.30 as payments
from customer_orders c
join 
runner_orders ro
on c.order_id = ro.order_id
where ro.cancellation is null or ro.cancellation = ''
)

select (revenue - payments) as profit
from metrics






