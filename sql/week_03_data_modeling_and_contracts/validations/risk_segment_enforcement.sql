SELECT DISTINCT risk_segment
FROM dim_customer
WHERE risk_segment NOT IN ('Low', 'Medium', 'High');
