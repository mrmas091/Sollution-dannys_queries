SELECT * FROM members
SELECT * FROM sales
SELECT * FROM menu


--1)What is the total amount each customer spent at the restaurant?

		SELECT CUSTOMER_id,SUM(price) total_amount
		FROM menu c
		JOIN sales M 
			ON C.product_id = M.product_id
		GROUP BY m.customer_id;

--2)How many days has each customer visited the restauran?

		SELECT customer_id,COUNT(DISTINCT(order_date) ) days_visited
		FROM sales
		GROUP BY customer_id;

--3)What was the first item from the menu purchased by each customer?

		SELECT F.customer_id,M.product_name 
		FROM
			(SELECT *,
					ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) first_pr 
					from sales) F
		JOIN menu M
			ON F.product_id = M.product_id
		WHERE f.first_pr = 1;

	--Check your sollution
		 SELECT * 
		 FROM sales m
		JOIN menu n
			ON  n.product_id = M.product_id;
--	4.	What is the most purchased item on the menu and how many times was it purchased by all customers?
		select TOP 1 M.product_name,P.product_count
		from (	SELECT  COUNT(*) product_count,product_id 
				FROM sales
				GROUP BY product_id
			) p
		join menu m 
			ON p.product_id = M.product_id
		ORDER BY P.product_count DESC;

--	5.	Which item was the most popular for each customer?
		SELECT V.customer_id,V.top_product,m.product_name
		FROM (	SELECT s.customer_id,max(S.top_p) top_product
				FROM(
					SELECT *,ROW_NUMBER() OVER(PARTITION BY customer_id,Product_id order by Product_id) top_p
					FROM sales
					) S
				GROUP  BY s.customer_id							---USING SUBQUERY
			)V
		JOIN menu M
			ON v.top_product=M.product_id
		GROUP BY v.customer_id,m.product_name,v.top_product;

/********************************************************
		WITH RankedSales AS (
			SELECT *,
				   ROW_NUMBER() OVER (PARTITION BY customer_id, Product_id ORDER BY Product_id) AS top_p
			FROM sales
		)
		SELECT V.customer_id, V.top_product, M.product_name
		FROM (
			SELECT customer_id, MAX(top_p) AS top_product		---USNIG WITH CLAUSE				
			FROM RankedSales
			GROUP BY customer_id
		) V
		JOIN menu M ON V.top_product = M.product_id
		GROUP BY V.customer_id, M.product_name, V.top_product;
**************************************************************************/

--	6.	Which item was purchased first by the customer after they became a member?
		WITH ranked AS
		(
		SELECT *,ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE ASC) FIRST_P
		FROM sales
		) 
		SELECT S.CUSTOMER_ID,ME.product_name
		FROM RANKED S
		JOIN members M 
			ON M.customer_id=S.customer_id AND M.join_date >= S.order_date
		JOIN menu ME
			ON s.product_id = me.Product_id
		WHERE S.FIRST_P = 1;

--	7.	Which item was purchased just before the customer became a member?
		
		WITH ranked AS
			(			
				SELECT M.customer_id,s.order_date,S.product_id,
							ROW_NUMBER() 
								OVER(PARTITION BY s.CUSTOMER_ID ORDER BY s.ORDER_DATE DESC ) FIRST_P 
				FROM members M
				JOIN sales S
					ON M.join_date >S.order_date AND M.customer_id=S.customer_id
				
			),
		final AS 
		(
		SELECT customer_id ,
				CASE  
					WHEN customer_id = 'A' THEN MAX(FIRST_P)
					ELSE MIN(first_p)
				END AS product
			FROM RANKED R
			GROUP BY customer_id
		)
		SELECT customer_id,product_name,product 
		FROM final p
		JOIN menu m
			ON p.product = m.product_id
		GROUP BY customer_id,m.product_name,product


--	8.	What is the total items and amount spent for each member before they became a member?
	
		SELECT S.customer_id,COUNT(*) total_items,SUM(PRICE) amount_spent
		FROM sales S
		JOIN menu M
			ON S.product_id=M.product_id
		JOIN members ME
			ON ME.join_date >S.order_date
			AND ME.customer_id=S.customer_id
		GROUP BY S.customer_id;
--	9.	If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
		
		WITH cte AS
		(
		select s.product_id,product_name,
		case 
			when u.product_name = 'sushi' then price*10*2
		else	price*10 
		end 
			uprice,customer_id
			 from menu u
		join sales s 
			on u.product_id = s.product_id
			)
		select customer_id,sum(uprice) total_points from cte
		group by customer_id;

--	10.	In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

		WITH CTE AS
			(	
			SELECT
				s.customer_id,
				JOIN_DATE,
				order_date,
				me.price,
				DATEDIFF(DAY, JOIN_DATE, order_date) diff,
				CASE 
					WHEN S.order_date >= M.join_date 
							AND DATEDIFF(DAY, JOIN_DATE, order_date) <= 6 THEN 2 * price
						ELSE price
				END AS calculated_points
			FROM
				sales s
			JOIN members m
				ON s.customer_id=m.customer_id
			JOIN menu me
				ON s.product_id=me.product_id
			WHERE
				 order_date <'2023-02-01'
			)
		SELECT customer_id,SUM(calculated_points) total_points 
		FROM CTE
		GROUP BY customer_id
		
