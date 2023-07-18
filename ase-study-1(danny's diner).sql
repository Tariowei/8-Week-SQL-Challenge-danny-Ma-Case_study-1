CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  -- 1. What is the total amount each customer spent at the restaurant?
  
  SELECT sales.customer_id, SUM(menu.price) AS total_amount_spent
 FROM sales,menu
 WHERE sales.product_id = menu.product_id
 GROUP BY sales.customer_id;
 
-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS num_visit_days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_item AS(
SELECT customer_id, product_name, order_date,
ROW_NUMBER () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS occurence
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id)
SELECT customer_id, product_name
FROM first_item 
WHERE occurence = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select menu.product_name, COUNT(sales.product_id) AS total_purchase
FROM sales, menu
WHERE sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY COUNT(sales.product_id) DESC
LIMIT 1;

SELECT sales.customer_id, menu.product_name, COUNT(menu.product_id) AS num_purchased
FROM sales, menu
WHERE sales.product_id = menu.product_id AND 
menu.product_name = "ramen"
GROUP BY customer_id;

-- 5. Which item was the most popular for each customer?
WITH popular_item AS(
SELECT customer_id,COUNT(sales.product_id),product_name,
RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(sales.product_id) DESC) AS occurence
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id 
GROUP BY customer_id, product_name)
SELECT customer_id, product_name, occurence
FROM popular_item
WHERE occurence = 1; 


-- 6. Which item was purchased first by the customer after they became a member?

WITH pam AS(
SELECT sales.customer_id, order_date,product_name, menu.product_id, join_date,
RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date ASC) AS occurence
FROM sales
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date >= join_date)
SELECT customer_id, order_date, product_name,join_date
FROM pam
WHERE occurence = 1; 

-- 7. Which item was purchased just before the customer became a member?

WITH pam AS(
SELECT sales.customer_id, order_date,product_name, menu.product_id, join_date,
RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS occurence
FROM sales
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date < join_date)
SELECT customer_id, order_date, product_name,join_date
FROM pam
WHERE occurence = 1; 

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 	sales.customer_id, SUM(sales.product_id) AS total_item, SUM(price) AS amount_spent
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
INNER JOIN members
ON sales.customer_id = members.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT sales.customer_id,
       SUM(CASE 
       ) as point_earned
FROM sales
INNER JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sales.customer_id,
       SUM(CASE 
       WHEN order_date BETWEEN join_date AND ADDDATE(join_date,7) THEN price*20 
       WHEN product_name = 'sushi' THEN price*20 ELSE price*10 END) as point_earned
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
INNER JOIN members
ON sales.customer_id = members.customer_id
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY sales.customer_id;
