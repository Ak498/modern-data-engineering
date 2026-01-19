/* ============================================================
   WEEK 1 � ADVANCED SQL PATTERNS (PORTFOLIO)
   Author: Akinrinola Akande

   Purpose:
   Demonstrate senior-level SQL thinking by solving common
   analytics problems using multiple approaches, with explicit
   tradeoffs, assumptions, and engine-specific considerations.

   Skills Demonstrated:
   - Window functions & ranking patterns
   - Grain awareness and semantic correctness
   - COUNT(DISTINCT) workarounds
   - SQL Server�specific optimizations
   - Analytical reasoning and edge-case handling
   ============================================================ */

/* ------------------------------------------------------------
   ENVIRONMENT & ASSUMPTIONS
   ------------------------------------------------------------
   SQL Dialect: SQL Server
   Table: sales
   Table Grain: Order line (order_id + sku)
   Dataset Size Assumption: Medium (10M�100M rows)

   NOTE:
   - Queries assume `status = 'Shipped - Delivered to Buyer'`
     is the only revenue-recognized state.
   - Currency conversions are intentionally not performed.
   ------------------------------------------------------------ */

/* ------------------------------------------------------------
   HOW TO READ THIS FILE
   ------------------------------------------------------------
   - Each problem is solved using multiple SQL patterns
   - Comments explain WHY a pattern is chosen, not just HOW
   - Engine-specific limitations are called out explicitly
   - The goal is correctness, clarity, and scalability
   ------------------------------------------------------------ */


   /* ------------------------------------------------------------
   PROBLEM 1: Rank orders per SKU by order date
   Business Question:
   For each SKU, what is the most recently delivered order?
   ------------------------------------------------------------ */

-- USE Transactions; -- Uncomment when running locally
--METHOD 1: CTE
--WHY: Most readable

WITH CTE AS (
	SELECT 
	  sku
	  , order_id
	  , date
	  , amount
	  , ship_service_level
	  , ROW_NUMBER() OVER (
		    PARTITION BY sku
		    ORDER BY date DESC
			    , order_id DESC
		 ) AS recent_rank
	FROM sales
	-- Filtering before windowing prevents ranking irrelevant statuses
	WHERE status = 'Shipped - Delivered to Buyer'
)
SELECT
  sku
  , order_id
  , date
  , amount
  , ship_service_level
FROM CTE
WHERE recent_rank = 1;

--METHOD 2: CORRELATED SUBQUERY
--WHY: works but can be harder to read

SELECT 
  sku
  , order_id
  , date
  , amount
  , ship_service_level
FROM sales AS s
WHERE s.status = 'Shipped - Delivered to Buyer'
  AND s.date = (SELECT MAX(s2.date) 
				FROM sales AS s2 
				WHERE s.sku = s2.sku
				  AND s.status = s2.status)
-- This approach assumes order_id increases with date.
-- If not guaranteed, this method can fail.
  AND s.Order_ID = (SELECT MAX(s3.order_id) 
					FROM sales AS s3 
					WHERE s.sku = s3.sku
					  AND s.date = s3.date
					  AND s.status = s3.status)

--Q Why filter status before ranking? 
--A TO ensure we are picking the order with the right status
-- Q Why add order_id as a tie-breaker?
--A since there is no time added to the date, adding order_id breaks ties when an sku has multiple orders on the same day


  /* ------------------------------------------------------------
   PROBLEM 2: How much revenue does each fulfilment method generate?
   ------------------------------------------------------------ */

--METHOD 1: GROUP BY
--WHY: Short and intuitive
SELECT 
  Fulfilment
  , currency
  , SUM(Amount) AS Revenue
  , COUNT(DISTINCT order_id) AS total_orders
FROM sales
WHERE status = 'Shipped - Delivered to Buyer'
GROUP BY Fulfilment, currency;

--METHOD 2: WINDOWS FUNCTION
--WHY:  Emulates COUNT(DISTINCT) with window functions when DISTINCT is not allowed in windows

WITH order_cte AS (
  SELECT DISTINCT
    Fulfilment
    , currency
    , order_id
    , SUM(Amount) OVER (
        PARTITION BY Fulfilment
          , currency
      ) AS Revenue
    , ROW_NUMBER() OVER (
        PARTITION BY Fulfilment
          , currency
          , order_id 
        ORDER BY order_id
      ) AS order_rnk
  FROM sales
  WHERE status = 'Shipped - Delivered to Buyer'
)
SELECT DISTINCT
  Fulfilment
  , currency
  , Revenue
  , SUM(CASE WHEN order_rnk = 1 then 1 END) OVER (
      PARTITION BY Fulfilment
        , currency
    ) AS total_orders
FROM order_cte;

--Q Why group by currency?
--A Revenue has to be by currency

--Q Why COUNT(DISTINCT order_id) instead of COUNT(*)?
--A To ignore duplicates when counting

 /* ------------------------------------------------------------
   PROBLEM 3: Show daily revenue trends per currency.?
   ------------------------------------------------------------ */
--METHOD 1: WINDOWS function 
--WHY: short but slighty harder to grasp
SELECT 
  currency
  , Date
  , SUM(AMOUNT) AS daily_revenue
  , SUM(SUM(AMOUNT)) OVER (
      PARTITION BY currency 
      ORDER BY Date
    ) AS cumulative_revenue
FROM sales
WHERE status = 'Shipped - Delivered to Buyer'
GROUP BY currency, Date;

--METHOD 2: GROUP BY + CTE
--WHY: slightly longer but more readable alternative
WITH daily_sales AS (
    SELECT
      date
      , currency
      , SUM(amount) AS daily_revenue
    FROM sales
    WHERE status = 'Shipped - Delivered to Buyer'
    GROUP BY date, currency
)
SELECT
  date
  , currency
  , daily_revenue
  , SUM(daily_revenue) OVER (
      PARTITION BY currency
      ORDER BY date
    ) AS cumulative_revenue
FROM daily_sales;

--Q Why not mix currencies?
-- A The revenue would be incorrect and we also would not have a specific currency for the total revenue
--Q Why compute cumulative after aggregation?
-- A cumulative revenue needed the daily revenenue which could only be derived by aggregation

/* ------------------------------------------------------------
   PROBLEM 4: For each shipping service level, what are the top 3 SKUs by revenue in INR?
   ------------------------------------------------------------ */
WITH sku_sales AS (
  SELECT 
    ship_service_level
    , sku
    , SUM(Amount) AS revenue
  FROM sales
  WHERE status = 'Shipped - Delivered to Buyer'
    AND currency = 'INR'
  GROUP BY ship_service_level, sku 
)
, sku_ranking AS (
   SELECT 
     ship_service_level
     , sku
     , revenue
     -- DENSE_RANK is used to preserve ties in revenue
	   , DENSE_RANK() OVER (
		     PARTITION BY  ship_service_level
		     ORDER BY revenue DESC
	     ) AS sku_rank
   FROM sku_sales 
  )
SELECT 
  ship_service_level
  , sku
  , revenue
FROM sku_ranking
WHERE sku_rank <= 3;

--Q. Why aggregate before ranking?
--A. The rsult of the aggregate is what we need to rank
--Q. When would ROW_NUMBER be better than RANK?
--A. In cases such as these when we don't want any records having the same rank.
--In this case however, there may be multiple skus with the same revenue and we want to ensure they are seen as high revenue generating.

/* ------------------------------------------------------------
   PROBLEM 5: Detect gaps between consecutive orders more than 30 days?
   This analysis detects gaps between consecutive fulfilled orders.
   It does NOT detect SKUs with no orders in the last 30 days relative to today.
   ------------------------------------------------------------ */
--METHOD 1: WINDOWS FUNCTION + CTE
--WHY: Simple and short
WITH ordered_sales AS (
  SELECT
    order_id
    , sku
    , fulfilment
    , date
    , LAG(date) OVER (
        PARTITION BY sku
        ORDER BY date
      ) AS prev_order_date
  FROM sales
  WHERE status = 'Shipped - Delivered to Buyer'
)
SELECT
  sku
  , order_id
  , date
  , DATEDIFF(DAY, prev_order_date, Date) AS gap_days
FROM ordered_sales
WHERE prev_order_date IS NOT NULL
  AND DATEDIFF(DAY, prev_order_date, Date) > 30;

  --select top 10 * from sales where order_id in (
  --select order_id from sales group by order_id having count(*) > 1) order by order_id

--MTHOD 2: INLINE WINDOWS FUNCTION
--WHY: works in snowflake but not in sql server
SELECT
  sku,
  , order_id
  , date
  , DATEDIFF( DAY, LAG(date) OVER (PARTITION BY sku ORDER BY date), date) AS gap_days
FROM sales
WHERE status = 'Shipped - Delivered to Buyer'
QUALIFY DATEDIFF( DAY,LAG(date) OVER (PARTITION BY sku ORDER BY date), date) > 30;

--METHOD 3: 
--WHY: tricky but works nicely
WITH numbered_orders AS (
  SELECT
    order_id
    , sku
    , date
    , ROW_NUMBER() OVER (
        PARTITION BY sku
        ORDER BY date
      ) AS rn
    FROM sales
    WHERE status = 'Shipped - Delivered to Buyer'
)
SELECT
  curr.sku,
  , curr.order_id
  , curr.date
  , DATEDIFF(DAY, prev.date, curr.date) AS gap_days
FROM numbered_orders curr
INNER JOIN numbered_orders prev
  ON curr.sku = prev.sku
  AND curr.rn = prev.rn + 1
WHERE DATEDIFF(DAY, prev.date, curr.date) > 30;

--METHOD 4:CROSS APPLY (works only in sql server)
--WHY: SHORT query and effective
SELECT
  s.sku
  , s.order_id
  , s.date
  , DATEDIFF(DAY, p.prev_date, s.date) AS gap_days
FROM sales s
CROSS APPLY (
  SELECT 
    TOP 1 date AS prev_date
  FROM sales s2
  WHERE s2.sku = s.sku
    AND s2.date < s.date
    AND s2.status = 'Shipped - Delivered to Buyer'
  ORDER BY s2.date DESC
) p
WHERE s.status = 'Shipped - Delivered to Buyer'
  AND DATEDIFF(DAY, p.prev_date, s.date) > 30;

--Answer these explicitly:

--Q. What is the grain of the sales table?
--A. The grain is order line level (order_id + sku). One order can contain multiple SKUs.

--Q. Which queries are order-level vs SKU-level?
--A. --A. Queries 1, 4, and 5 produce SKU-level analytical outputs, query 2 has a fulfilment grain and query 3 has a date grain

--Q. What assumptions did you make about status?
--A I assumed that the status of 'Shipped - Delivered to Buyer' is the only status that revenue can be accrued for.

--Q. What breaks if refunds or partial shipments exist?
--A This would mean the revenue would be incorrect in some cases. There are status like 'Shipped - Returning to Seller', 'Shipped - Returned to Seller',
-- 'Shipped - Rejected by Buyer' and 'Shipped - Lost in Transit' that inidicate a refund might be due.


-- Key  Takeaways:
-- 1. Window functions require careful grain control
-- 2. Filtering before vs after windowing changes semantics
-- 3. COUNT(DISTINCT) limitations require architectural thinking
