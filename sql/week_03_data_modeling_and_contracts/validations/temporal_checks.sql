-- Repayment date should not be earlier than loan origination date
SELECT r.loan_id,
       r.date_id AS repayment_date_id,
       l.date_id AS loan_date_id
FROM fact_repayment r
INNER JOIN fact_loan l
  ON r.loan_id = l.loan_id
WHERE r.date_id < l.date_id;
