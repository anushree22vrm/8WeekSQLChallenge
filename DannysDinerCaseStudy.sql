create database danny_diner

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INT
);
GO

INSERT INTO sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
GO

CREATE TABLE menu (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(20),
    price INT
);
GO

INSERT INTO menu (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
GO

CREATE TABLE members (
    customer_id VARCHAR(1) PRIMARY KEY,
    join_date DATE
);
GO

INSERT INTO members (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
GO

-- Case Study Questions

-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(m.price) as total_amt_spent
from sales s
join 
menu m
on s.product_id = m.product_id
group by s.customer_id

-- 2. How many days has each customer visited the restaurant?

select customer_id,count(order_date) as days_visited
from sales
group by customer_id

-- 3. What was the first item from the menu purchased by each customer?

with first_orders as
(
 select s.customer_id,s.order_date,m.product_name,rank() over(partition by customer_id order by order_date) as ranks
 from sales s
 join
 menu m
 on s.product_id = m.product_id
)
select customer_id,order_date,product_name
from first_orders
where ranks = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with most_purchased_item as
(
 select top 1 m.product_id, m.product_name,count(*) as most_purchased_item_count
 from sales s
 join 
 menu m
 on s.product_id = m.product_id
 group by m.product_name,m.product_id
 order by most_purchased_item_count desc
)
 select s.customer_id,mpi.product_name,mpi.most_purchased_item_count,count(*) as cust_purchase_count
 from 
 sales s
 join
 most_purchased_item mpi
 on s.product_id = mpi.product_id
 group by customer_id,mpi.most_purchased_item_count,mpi.product_name

 -- 5. Which item was the most popular for each customer?
 with total_purchases as
 (
  select s.customer_id,s.product_id,m.product_name,count(*) as purchase_count
  from sales s
  join
  menu m
  on s.product_id = m.product_id
  group by s.customer_id,s.product_id,m.product_name
  
)
select customer_id,product_name,purchase_count
from total_purchases
where purchase_count =
( select max(purchase_count)
  from total_purchases
)

--chatgpt solution
with total_purchases as
(
  select 
    s.customer_id,
    s.product_id,
    m.product_name,
    count(*) as purchase_count
  from sales s
  join menu m
    on s.product_id = m.product_id
  group by s.customer_id, s.product_id, m.product_name
)
select customer_id, product_name, purchase_count
from total_purchases t1
where purchase_count = (
    select max(purchase_count)
    from total_purchases t2
    where t2.customer_id = t1.customer_id
);


-- 6. Which item was purchased first by the customer after they became a member?
with first_order_post_member as
(
 select s.customer_id,r.join_date,s.product_id,m.product_name,Row_number() over(partition by s.customer_id order by s.order_date) as ranks
 from sales s
 join members r
 on s.customer_id = r.customer_id
 join
 menu m
 on s.product_id = m.product_id
 where s.order_date > r.join_date
)

select customer_id,product_name
from first_order_post_member
where ranks = 1


-- 7. Which item was purchased just before the customer became a member?
with order_before_member as
(
  select s.customer_id,s.order_date,r.join_date,m.product_name,row_number() over(partition by s.customer_id order by s.order_date desc) as ranks
  from sales s
  join members r
  on s.customer_id = r.customer_id
  join 
  menu m
  on s.product_id = m.product_id
  where s.order_date < r.join_date
)
select customer_id,product_name
from order_before_member
where ranks = 1

-- 8. What is the total items and amount spent for each member before they became a member?

 select s.customer_id,count(*) as total_items, sum(price) as amount_spent
 from sales s
 join members r
 on s.customer_id = r.customer_id
 join 
 menu m
 on s.product_id = m.product_id
 where s.order_date < r.join_date
 group by s.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id,
sum
(
 case when m.product_name = 'sushi' then (m.price*10)*2
 else price * 10
 end
) as points
from sales s
join
menu m
on s.product_id = m.product_id
group by s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id, 
sum
(case when s.order_date between r.join_date and dateadd(day,6,r.join_date) then (m.price*10)*2
 when m.product_name = 'sushi' then (m.price*10)*2
 else m.price*10
 end
) as points
from sales s
join
members r
on s.customer_id = r.customer_id
join menu m
on s.product_id = m.product_id
where s.order_date >= r.join_date
group by s.customer_id
