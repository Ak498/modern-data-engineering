-- Repayment amount should equal the sum of principal, interest, and penalty
SELECT *
FROM fact_repayment
WHERE repayment_amount 
      <> principal_component 
         + interest_component 
         + penalty_amount;


-- Repayments should not exceed the loan amount
SELECT l.loan_id
FROM fact_loan l
JOIN fact_repayment r
  ON l.loan_id = r.loan_id
GROUP BY l.loan_id, l.loan_amount
HAVING SUM(r.principal_component) > l.loan_amount;
