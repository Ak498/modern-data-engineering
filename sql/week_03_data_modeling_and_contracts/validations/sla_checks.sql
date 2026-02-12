-- Max loan origination date should be today (or very recent)
SELECT MAX(d.full_date) AS max_loan_date
FROM fact_loan l
JOIN dim_date d
  ON l.date_id = d.date_id
HAVING MAX(d.full_date) < CAST(GETDATE() AS DATE);
