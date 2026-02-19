WITH daily_metrics AS (
  SELECT
    origination_date
    , COUNT(*) AS loans
    , SUM(loan_amount) AS loan_amount
  FROM fact_loan
  GROUP BY origination_date
)
-- 7 day rolling metrics
SELECT
   origination_date
  , SUM(loans) OVER (
      ORDER BY origination_date
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_loans
FROM daily_metrics;

-- 30 day rolling metrics 
SELECT
   origination_date
  , SUM(loans) OVER (
      ORDER BY origination_date
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_loans
FROM daily_metrics;

-- 90 day rolling metrics
SELECT
   origination_date
  , SUM(loans) OVER (
      ORDER BY origination_date
      ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ) AS rolling_90d_loans
FROM daily_metrics;










