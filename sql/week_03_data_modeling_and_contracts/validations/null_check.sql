SELECT *
FROM fact_loan
WHERE loan_amount IS NULL
   OR customer_id IS NULL;
