WITH loan_base AS (
  SELECT
      l.loan_id
    , d.full_date AS origination_date
    , l.loan_amount
    , l.interest_rate
    , l.medium_id
    , l.employee_id
    , l.customer_id
  FROM fact_loan l
  JOIN dim_date d
    ON l.origination_date_id = d.date_id
)

, repayment_base AS (
  SELECT
      r.loan_id
    , d.full_date AS repayment_date
    , r.repayment_amount
    , r.principal_component
    , r.interest_component
    , r.penalty_amount
  FROM fact_repayment r
  JOIN dim_date d
    ON r.repayment_date_id = d.date_id
)

, repayment_agg AS (
  SELECT
      loan_id
    , SUM(principal_component) AS total_principal_repaid
    , SUM(repayment_amount) AS total_repaid
    , MAX(repayment_date) AS last_payment_date
  FROM repayment_base
  GROUP BY loan_id
)

-- 🔽 All KPI SELECT statements go below
--PORTFOLIO HEALTH KPIs

-- 1. Total Loan Originations (30d)
SELECT
    COUNT(DISTINCT loan_id) AS total_loans_originated
FROM loan_base
WHERE origination_date >= DATEADD(day, -29, GETDATE());

-- 2. Total Loan Amount Originated
SELECT
    SUM(loan_amount) AS total_loan_amount_originated
FROM loan_base    
WHERE origination_date >= DATEADD(day, -29, GETDATE());

-- 3. Average Loan Size (30d)
SELECT
    AVG(loan_amount) AS average_loan_size
FROM loan_base
WHERE origination_date >= DATEADD(day, -29, GETDATE());

-- 4. Outstanding Loan Balance
SELECT
    SUM(loan_amount) - SUM(COALESCE(total_principal_repaid, 0)) AS outstanding_loan_balance
FROM loan_base
LEFT JOIN repayment_agg
  ON loan_base.loan_id = repayment_agg.loan_id;

-- 5. Portfolio Size (Active Loans)
SELECT
    COUNT(DISTINCT loan_id) AS portfolio_size
FROM loan_base
WHERE loan_amount > total_principal_repaid;

-- FINANCIAL PERFORMANCE KPIs
-- 6. Total Repayments Collected(30d)
SELECT
    SUM(repayment_amount) AS total_repayments_collected
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE());

-- 7. Principal Collected
SELECT
    SUM(principal_component) AS total_principal_collected
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE());

-- 8. Interest Collected(30d)
SELECT
    SUM(interest_component) AS total_interest_collected
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE());

-- 9. Penalty Revenue(30d)
SELECT
    SUM(penalty_amount) AS total_penalty_revenue
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE());

-- 10. Collection Rate
SELECT
    (SUM(repayment_amount) / SUM(loan_amount)) * 100 AS collection_rate
FROM repayment_base
LEFT JOIN loan_base
  ON repayment_base.loan_id = loan_base.loan_id;
WHERE repayment_date >= DATEADD(day, -29, GETDATE());

--RISK KPIs

-- 11. Delinquency Rate
SELECT
    (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS delinquency_rate
FROM loan_base
LEFT JOIN repayment_agg
  ON loan_base.loan_id = repayment_agg.loan_id
WHERE repayment_agg.last_payment_date < DATEADD(day, -90, GETDATE());

-- 12. Late Payment Rate
SELECT
    (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS late_payment_rate
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE())
AND penalty_amount > 0;

-- 13. Average Days Past Due (DPD)
SELECT
    AVG(DATEDIFF(day, repayment_date, GETDATE())) AS average_days_past_due
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE())
AND penalty_amount > 0;

-- 14. Non-Performing Loans (NPL) Rate
SELECT
    (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS npl_rate
FROM loan_base
LEFT JOIN repayment_agg
  ON loan_base.loan_id = repayment_agg.loan_id
WHERE repayment_agg.last_payment_date < DATEADD(day, -90, GETDATE());

-- 15. At-Risk Loans
SELECT
    COUNT(DISTINCT loan_id) AS at_risk_loans
FROM loan_base
WHERE loan_amount > total_principal_repaid;

/*
-- RISK & DELINQUENCY KPIs

-- 16. Delinquency Rate by Risk Segment
SELECT
    risk_segment
    , COUNT(DISTINCT loan_id) AS delinquent_loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS delinquency_rate
FROM loan_base
LEFT JOIN repayment_agg
  ON loan_base.loan_id = repayment_agg.loan_id
WHERE repayment_agg.last_payment_date < DATEADD(day, -90, GETDATE());
GROUP BY risk_segment;

-- 17. At-Risk Loans by Risk Segment
SELECT
    risk_segment
    , COUNT(DISTINCT loan_id) AS at_risk_loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS at_risk_rate
FROM loan_base
LEFT JOIN repayment_agg
  ON loan_base.loan_id = repayment_agg.loan_id
WHERE loan_amount > total_principal_repaid;
GROUP BY risk_segment;

-- 18. Average DPD by Risk Segment
SELECT
    risk_segment
    , AVG(DATEDIFF(day, repayment_date, GETDATE())) AS average_days_past_due
FROM repayment_base
LEFT JOIN loan_base
  ON repayment_base.loan_id = loan_base.loan_id
WHERE repayment_date >= DATEADD(day, -29, GETDATE())
AND penalty_amount > 0;
GROUP BY risk_segment;
*/

-- OPERATIONAL KPIs

-- 19. Loans by Channel (Medium)
SELECT
    medium_name
    , COUNT(DISTINCT loan_id) AS loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS loan_rate
FROM loan_base
LEFT JOIN dim_medium
  ON loan_base.medium_id = dim_medium.medium_id;

-- 20. Loans by Employee
SELECT
    employee_code
    , branch
    , COUNT(DISTINCT loan_id) AS loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS loan_rate
FROM loan_base
LEFT JOIN dim_employee
  ON loan_base.employee_id = dim_employee.employee_id;

-- 21. Loans by Branch  
SELECT
    branch
    , COUNT(DISTINCT loan_id) AS loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS loan_rate
FROM loan_base
LEFT JOIN dim_employee
  ON loan_base.employee_id = dim_employee.employee_id;

-- 22. Loans by Risk Segment
SELECT
    risk_segment
    , COUNT(DISTINCT loan_id) AS loans
    , (COUNT(DISTINCT loan_id) / COUNT(DISTINCT loan_id)) * 100 AS loan_rate  
FROM loan_base
LEFT JOIN dim_customer
  ON loan_base.customer_id = dim_customer.customer_id;

-- 23. Average Interest Rate by Segment
SELECT
    risk_segment
    , AVG(interest_rate) AS average_interest_rate
FROM loan_base
LEFT JOIN dim_customer
  ON loan_base.customer_id = dim_customer.customer_id;

-- REPAYMENT BEHAVIOR KPIs

-- 24. Repayment Rate (Loans With >=1 Repayment)
SELECT
    COUNT(DISTINCT r.loan_id) * 1.0
  / COUNT(DISTINCT l.loan_id) * 100 AS repayment_rate
FROM loan_base l
LEFT JOIN repayment_base r
  ON l.loan_id = r.loan_id
WHERE origination_date >= DATEADD(day, -90, GETDATE());


-- 25. Average Repayment Amount(30d)
SELECT
    AVG(repayment_amount) AS average_repayment_amount 
FROM repayment_base
WHERE repayment_date >= DATEADD(day, -29, GETDATE());
