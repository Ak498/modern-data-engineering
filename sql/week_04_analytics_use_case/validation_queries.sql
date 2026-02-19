-- Repayment should not exceed principal
SELECT
  l.loan_id
  , l.loan_amount
  , SUM(r.principal_component) AS total_principal
FROM fact_loan l
LEFT JOIN fact_repayment r
  ON l.loan_id = r.loan_id
GROUP BY
  l.loan_id
  , l.loan_amount
HAVING SUM(r.principal_component) > l.loan_amount;

-- Repayment should not exceed loan amount
SELECT
  l.loan_id
  , l.loan_amount
  , SUM(r.repayment_amount) AS total_repayment
FROM fact_loan l
LEFT JOIN fact_repayment r
  ON l.loan_id = r.loan_id
GROUP BY
  l.loan_id
  , l.loan_amount
HAVING SUM(r.repayment_amount) > l.loan_amount;

-- No negative balances
SELECT
  l.loan_id
  , l.loan_amount
  , SUM(r.principal_component) AS total_principal
  , SUM(r.interest_component) AS total_interest
  , SUM(r.penalty_amount) AS total_penalty
FROM fact_loan l
LEFT JOIN fact_repayment r
  ON l.loan_id = r.loan_id
GROUP BY
  l.loan_id
  , l.loan_amount
HAVING SUM(r.principal_component) + SUM(r.interest_component) + SUM(r.penalty_amount) < l.loan_amount;

--Delinquency rate between 0 and 100%
SELECT
  (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS delinquency_rate
FROM fact_loan
LEFT JOIN fact_repayment
  ON fact_loan.loan_id = fact_repayment.loan_id
WHERE fact_repayment.repayment_date < DATEADD(day, -90, GETDATE())
AND fact_repayment.penalty_amount > 0;

--collection  rate between 0 and 100%
SELECT
  (SUM(repayment_amount) / SUM(loan_amount)) * 100 AS collection_rate
FROM fact_loan
LEFT JOIN fact_repayment
  ON fact_loan.loan_id = fact_repayment.loan_id
WHERE fact_repayment.repayment_date >= DATEADD(day, -29, GETDATE());
HAVING (SUM(repayment_amount) / SUM(loan_amount)) * 100 > 100;

