-- No duplicate loans
SELECT loan_id
FROM fact_loan
GROUP BY loan_id
HAVING COUNT(*) > 1;

-- No duplicate repayment transactions
SELECT repayment_id
FROM fact_repayment
GROUP BY repayment_id
HAVING COUNT(*) > 1;
