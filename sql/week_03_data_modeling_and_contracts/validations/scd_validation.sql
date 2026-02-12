-- No overlapping effective periods
SELECT customer_id
FROM dim_customer
GROUP BY customer_id, effective_start_date
HAVING COUNT(*) > 1;
