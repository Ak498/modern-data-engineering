/*============================================================
   WEEK 2 — SQL PERFORMANCE & OPTIMIZATION
   Author: Akinrinola Akande

   Goal:
   Identify slow queries, analyze execution plans,
   apply indexing and query rewrites, and prove improvement.

   SQL Dialect: SQL Server
   Dataset Assumption: 1M rows
   Table Grain: Order line (order_id + sku)
   NOTE:
		-- At ~1M rows, benefits are moderate.
		-- These optimizations matter more at 10M+ rows.

============================================================*/


/* ------------------------------------------------------------
   PROBLEM 1: Rank orders per SKU by order date
   Business Question:
   For each SKU, what is the most recently delivered order?
   ------------------------------------------------------------ */
-- USE Transactions; -- Uncomment when running locally

-------------------------------------------------------------
-- INDEX CREATION
-- Purpose:
-- - Filter early on status
-- - Support GROUP BY sku
-------------------------------------------------------------

CREATE NONCLUSTERED INDEX idx_status_sales ON sales (status)
 INCLUDE (sku, order_id, date, amount, ship_service_level);

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

/*---problem 2-------*/
--METHOD 1: 
-- This approach is intentionally heavier to demonstrate
-- COUNT(DISTINCT) emulation, not preferred for performance.

WITH order_cte AS (
  SELECT DISTINCT
    Fulfilment
    , currency
    , order_id
    , SUM(Amount) OVER (PARTITION BY Fulfilment , currency ) AS Revenue
    , ROW_NUMBER() OVER (PARTITION BY Fulfilment  , currency, order_id  ORDER BY order_id) AS order_rnk
  FROM sales
  WHERE status = 'Shipped - Delivered to Buyer'
)
SELECT DISTINCT
  Fulfilment
  , currency
  , Revenue
  , SUM(CASE WHEN order_rnk = 1 then 1 END) OVER ( PARTITION BY Fulfilment, currency ) AS total_orders
FROM order_cte;

--METHOD 2: Query rewrite + nonclustered index

CREATE NONCLUSTERED INDEX idx_status_currency_sales ON sales (status)
 INCLUDE (sku, order_id, amount, fulfilment, currency);

SELECT 
  Fulfilment
  , currency
  , SUM(Amount) AS Revenue
  , COUNT(DISTINCT order_id) AS total_orders
FROM sales
WHERE status = 'Shipped - Delivered to Buyer'
GROUP BY Fulfilment, currency;

-- NOTE:
-- The two indexes created so far overlap.
-- In production, we would consolidate based on query frequency and write amplification tradeoffs.



/*-----------------PROBLEM 3------------------------*/
--METHOD 1:CROSS APPLY
-- Assumes index on (sku, date DESC) INCLUDE (status)

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
  AND DATEDIFF(DAY, p.prev_date, s.date) > 30
  AND p.prev_date IS NOT NULL;


  --METHOD 2: Query rewrite 

WITH UniqueDeliveredDates AS (

-- Deduplicate to SKU+date to avoid false gaps
-- caused by multiple orders on the same day.
    SELECT DISTINCT sku, date 
    FROM sales 
    WHERE status = 'Shipped - Delivered to Buyer'
),
DateGaps AS (
    SELECT 
      sku
      , date 
      , LAG(date) OVER (PARTITION BY sku ORDER BY date) AS prev_date
    FROM UniqueDeliveredDates
)
SELECT 
  s.sku
  , s.order_id
  , s.date 
  , DATEDIFF(DAY, g.prev_date, s.date) AS gap_days
FROM sales s
INNER JOIN DateGaps g ON s.sku = g.sku  AND s.date = g.date
WHERE s.status = 'Shipped - Delivered to Buyer'
  AND g.prev_date IS NOT NULL
  AND DATEDIFF(DAY, g.prev_date, s.date) > 30;

/* ------------------------------------------------------------
   PERFORMANCE SUMMARY
   ------------------------------------------------------------
   Observed improvements:
   - Table Scan → Index Seek
   - Reduced logical reads
   - Reduced memory grants

   Root causes:
   - Indexes aligned to WHERE + GROUP BY
   - Reduced need for sorts
   - Eliminated unnecessary DISTINCT operations
------------------------------------------------------------ */
