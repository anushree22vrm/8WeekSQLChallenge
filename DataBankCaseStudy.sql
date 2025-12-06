select * from regions
select * from customer_nodes
select * from customer_transactions

--  A. Customer Nodes Exploration

-- How many unique nodes are there on the Data Bank system?
select COUNT(distinct node_id) as unique_nodes_count
from customer_nodes

-- What is the number of nodes per region?
select r.region_id,r.region_name,COUNT(n.node_id) as nodes_count
from regions r
join
customer_nodes n
on r.region_id = n.region_id
group by r.region_id,r.region_name
order by r.region_id

-- How many customers are allocated to each region?
select r.region_id,r.region_name,COUNT(customer_id) as cust_count
from regions r
join
customer_nodes n
on r.region_id = n.region_id
group by r.region_id,r.region_name
order by r.region_id

-- How many days on average are customers reallocated to a different node?
select avg(DATEDIFF(DAY,start_date,end_date)) as overall_avg
from customer_nodes

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with percentile_cal as
(
 select r.region_id,r.region_name,
 percentile_cont (0.50) within group (order by datediff(day,n.start_date,n.end_date)) over(partition by r.region_id) as median_days,
 percentile_cont (0.80) within group (order by datediff(day,n.start_date,n.end_date)) over(partition by r.region_id) as p_80th,
 percentile_cont (0.95) within group (order by datediff(day,n.start_date,n.end_date)) over(partition by r.region_id) as p_90th
 from regions r
 join
 customer_nodes n
 on r.region_id = n.region_id
)
select distinct region_id,region_name,median_days,p_80th,p_90th
from percentile_cal
order by region_id

-- B. Customer Transactions

--What is the unique count and total amount for each transaction type?
select txn_type,COUNT(distinct customer_id) as unique_count,SUM(txn_amount) as total_amt
from customer_transactions
group by txn_type

--What is the average total historical deposit counts and amounts for all customers?
select AVG(deposit_count) as avg_deposits,AVG(total_amt) as avg_amt
from
(
 select customer_id,COUNT(*) as deposit_count,SUM(txn_amount) as total_amt
 from customer_transactions
 where txn_type = 'deposit'
 group by customer_id
)t


--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

select month_num, sum(case when deposit_count > 1 and (purchase_count >= 1 or withdrawal_count >=1) then 1 else 0 end) as counts
from
(
 select customer_id,DATEPART(MONTH,txn_date) as month_num,sum(case when txn_type = 'deposit' then 1 else 0 end) as deposit_count,
 sum(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawal_count,
 SUM(case when txn_type = 'purchase' then 1 else 0 end) as purchase_count
 from customer_transactions
 group by customer_id,DATEPART(MONTH,txn_date)
)t 
group by month_num
order by month_num

--What is the closing balance for each customer at the end of the month?
select customer_id,DATEPART(MONTH,txn_date) as month_num, 
SUM(
    case 
     when txn_type = 'deposit' then txn_amount
     when txn_type = 'withdrawal' then -txn_amount
     when txn_type = 'purchase' then -txn_amount
     else 0
    end
   ) as closing_balance
from customer_transactions
group by customer_id,DATEPART(MONTH,txn_date)
order by customer_id,month_num

--What is the percentage of customers who increase their closing balance by more than 5%?
with monthly_cb as
(
 select customer_id,DATEPART(MONTH,txn_date) as month_num,
 SUM(
     case 
      when txn_type = 'deposit' then txn_amount
      when txn_type in('withdrawal','purchase') then -txn_amount
      else 0
     end
    ) as closing_bal
 from customer_transactions
 group by customer_id,DATEPART(MONTH,txn_date)
 --order by customer_id,month_num
),

bal_changes as
(
 select customer_id,MONTH_num,closing_bal,LAG(closing_bal) over(partition by customer_id order by month_num) as prev_balance
 from monthly_cb
),

increased as
(
 select customer_id,month_num,closing_bal,prev_balance,
 case when prev_balance is not null and closing_bal > prev_balance * 1.05 then 1 else 0 end as increase_flag
 from bal_changes
)
select (cast(COUNT(distinct case when increase_flag = 1 then customer_id end) as float)/COUNT(distinct customer_id)) * 100 as percent_cust_increased
from increased
 

--running customer balance column that includes the impact each transaction
select customer_id,txn_date,txn_type,txn_amount,
SUM
 (case
   when txn_type = 'deposit' then txn_amount
   when txn_type = 'withdrawal' then -txn_amount
   when txn_type = 'purchase' then -txn_amount
  end
 ) over (partition by customer_id order by txn_date rows between unbounded preceding and current row) as running_sum
from customer_transactions

/*  C. Data Allocation Challenge

To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time

*/

--customer balance at the end of each month
select customer_id,DATEPART(MONTH,txn_date) as month_num,
SUM
 ( case 
    when txn_type = 'deposit' then txn_amount
    when txn_type = 'withdrawal' then -txn_amount
    when txn_type = 'purchase' then -txn_amount
   end
 ) as closing_balance
from customer_transactions
group by customer_id,DATEPART(MONTH,txn_date)
order by customer_id,month_num

--minimum, average and maximum values of the running balance for each customer
with running_balance as
(
 select customer_id,txn_date,txn_type,txn_amount,
 SUM
  (case 
    when txn_type = 'deposit' then txn_amount
    when txn_type = 'withdrawal' then -txn_amount
    when txn_type = 'purchase' then -txn_amount
    else 0
   end
  ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) as running_total
 from customer_transactions
)
select customer_id,MIN(running_total) as min_value, MAX(running_total) as max_value, AVG(running_total) as avg_value
from running_balance
group by customer_id

--Using all of the data available - how much data would have been required for each option on a monthly basis?

--Option 1: data is allocated based off the amount of money at the end of the previous month
with closing_balance as
(
 select customer_id,DATEPART(MONTH,txn_date) as month_num,
 SUM
  ( case
     when txn_type = 'deposit' then txn_amount
     when txn_type in ('withdrawal','purchase') then -txn_amount
     else 0
    end
  ) as closing_bal
 from customer_transactions
 group by customer_id,DATEPART(MONTH,txn_date) 
)
select month_num,SUM(closing_bal) as data_required_option1
from closing_balance
group by month_num

--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
with running as
(
 select customer_id,txn_date,txn_type,txn_amount,
 SUM(case
      when txn_type = 'deposit' then txn_amount
      when txn_type in ('withdrawal','purchase') then -txn_amount
      else 0
     end
    ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) as running_total
 from customer_transactions
),
rolling_avg as
(
 select r1.customer_id,r1.txn_date,
 (
  select AVG(r2.running_total) 
  from running r2
  where r2.customer_id = r1.customer_id and r2.txn_date between DATEADD(DAY,-30,r1.txn_date) and r1.txn_date
 ) as avg_30_days
from running r1
)
select DATEPART(MONTH,txn_date) as month_num,
SUM(avg_30_days) as total_data_required_option2
from rolling_avg
group by DATEPART(MONTH,txn_date)
order by month_num


--Option 3: data is updated real-time
with running as
(
 select customer_id,txn_date,txn_type,txn_amount,
 SUM(case
      when txn_type = 'deposit' then txn_amount
      when txn_type in ('withdrawal','purchase') then -txn_amount
      else 0
     end
    ) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) as running_total
 from customer_transactions
)
select DATEPART(MONTH,txn_date) as month_num,SUM(running_total) as total_data_required_option3
from running
group by DATEPART(MONTH,txn_date)
order by month_num

/*  D. Extra Challenge

Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation,
just like in a traditional savings account you might have with a bank.If the annual interest rate is set at 6% and the Data Bank team wants to reward
its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be
required for this option on a monthly basis?

Special notes:
Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding
interest calculation so you can try to perform this calculation if you have the stamina!
*/

with daily_bal as
(
select customer_id,txn_date,
sum(closing_balance) over(partition by customer_id order by txn_date rows between unbounded preceding and current row) as EOD_balance
from
(
 select customer_id,txn_date,
 SUM(case 
      when txn_type = 'deposit' then txn_amount
      when txn_type in('withdrawal','purchase') then -txn_amount
      else 0
     end
    ) as closing_balance
 from customer_transactions
 group by customer_id,txn_date
)t
)
 select datepart(month,txn_date) as month_num, sum(case when EOD_balance < 0 then 0 else (EOD_balance*0.06)/365 end) as data_required
 from daily_bal
 group by datepart(month,txn_date)
 order by datepart(month,txn_date)