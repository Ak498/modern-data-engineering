-- Interest rate should be between 0 and 1
SELECT *
FROM fact_loan
WHERE interest_rate < 0 
   OR interest_rate > 1;

-- Tenure months should be greater than 0
SELECT *
FROM fact_loan
WHERE tenure_months <= 0;
