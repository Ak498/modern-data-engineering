-- Loans with missing customer dimension record
SELECT l.loan_id, l.customer_id
FROM fact_loan l
LEFT JOIN dim_customer c
  ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Loans with missing employee dimension record
SELECT l.loan_id, l.employee_id
FROM fact_loan l
LEFT JOIN dim_employee e
  ON l.employee_id = e.employee_id
WHERE e.employee_id IS NULL;

-- Loans with missing medium dimension record
SELECT l.loan_id, l.medium_id
FROM fact_loan l
LEFT JOIN dim_medium m
  ON l.medium_id = m.medium_id
WHERE m.medium_id IS NULL;

-- Loans with missing date dimension record
SELECT l.loan_id, l.date_id
FROM fact_loan l
LEFT JOIN dim_date d
  ON l.date_id = d.date_id
WHERE d.date_id IS NULL;

-- Repayments with missing parent loan
SELECT r.repayment_id, r.loan_id
FROM fact_repayment r
LEFT JOIN fact_loan l
  ON r.loan_id = l.loan_id
WHERE l.loan_id IS NULL;

-- Repayments with missing medium dimension record
SELECT r.repayment_id, r.medium_id
FROM fact_repayment r
LEFT JOIN dim_medium m
  ON r.medium_id = m.medium_id
WHERE m.medium_id IS NULL;

-- Repayments with missing date dimension record
SELECT r.repayment_id, r.date_id
FROM fact_repayment r
LEFT JOIN dim_date d
  ON r.date_id = d.date_id
WHERE d.date_id IS NULL;

