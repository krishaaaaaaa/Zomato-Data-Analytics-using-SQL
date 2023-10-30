
-- Creating "goldusers_signup" table and inserting values

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
VALUES (1,'2017-09-22'), (3,'2017-04-21');

-- Creating "users" table and inserting values

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'), 
(2,'2015-01-15'), 
(3,'2014-04-11'); 


-- Creating "sales" table and inserting values

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-18',2),
(3,'2019-12-18',1), 
(2,' 2019-12-18',3), 
(1,'2019-10-23',2), 
(1,'2018-03-19',3), 
(3,'2016-12-20',2), 
(1,'2016-11-09',1), 
(1,'2016-05-20',3), 
(2,'2017-09-24',1), 
(1,'2017-03-11',2), 
(1,'2016-03-11',1), 
(3,'2016-11-10',1), 
(3,'2017-12-07',2), 
(3,'2016-12-15',2), 
(2,'2017-11-08',2), 
(2,'2018-09-10',3); 


-- Creating "product" table and inserting values

drop table if exists product;
CREATE TABLE products(product_id integer,product_name varchar(20),price integer); 

INSERT INTO products(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


--Review data in each table

select * from sales;
select * from users;
select * from products;
select * from goldusers_signup;

--Alter Table name

alter table goldusers_signup rename to goldusers;


-- 1. what is total amount each customer spent on zomato?

select s.userid, sum(p.price) 
from sales s 
join products p 
on s.product_id = p.product_id 
group by s.userid 
order by s.userid;


-- 2. How many days has each customer visited zomato?

select userid, count(created_date) 
from sales 
group by userid
order by userid;


-- 3. what was the first product purchased by each customer?

select userid, product_id from
(select (rank() over (PARTITION BY userid  order by created_date)) r, userid, created_date, product_id from sales) a
where r=1;


-- 4. what is most purchased item on menu & how many times was it purchased by all customers?

select userid, count(*) from sales 
where product_id = (select product_id from sales group by product_id order by count(*) desc limit 1)
group by userid;


-- 5. which item was most popular for each customer?

select userid, product_id
from (
	select userid, product_id,  RANK() OVER (partition by userid Order BY COUNT(*) DESC ) freq
	from sales 
	group by userid, product_id
	) a
where freq = 1;


-- 6. which item was purchased first by customer after they become a member?

with cte as (
	select s.userid, s.created_date, s.product_id, 
	rank() over (partition by s.userid order by s.userid, created_date ) r
	from sales s 
	join goldusers g on s.userid=g.userid
	where created_date>=gold_signup_date)

select userid, product_id 
from cte
where r = 1;


-- 7. which item was purchased just before customer became a member?

with cte as (
	select s.userid, s.created_date, s.product_id, g.gold_signup_date,
	rank() over (partition by s.userid order by s.userid, created_date desc ) r
	from sales s 
	join goldusers g on s.userid=g.userid
	where created_date<=gold_signup_date)

select *
from cte
where r = 1;


-- 8. what is total orders and amount spent for each member before they become a member?

with cte as (
	select s.userid, s.created_date, s.product_id, g.gold_signup_date, p.price,
	rank() over (partition by s.userid order by s.userid, created_date desc ) r
	from sales s 
	join goldusers g on s.userid=g.userid
	join products p on p.product_id = s.product_id
	where created_date<=gold_signup_date)

select userid, count(*) no_of_orders, sum(price) total_spent
from cte
group by userid;


-- 9. rank all transaction of the customers 

select *,
	rank() over(partition by userid,product_id order by created_date) 
from sales;


-- 10. rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na

select  *, (case when transction = '0' then 'NA' ELSE transction END) as r_transction
from
(
	select *, 
		cast((case
			when g.userid is null then 0
			else rank() over(partition by g.userid order by created_date desc)
			end
	 		 ) as varchar
			) as transction
	from sales as s
	left join goldusers as g on s.userid = g.userid
	) as A
	
