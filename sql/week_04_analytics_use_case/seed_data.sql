/*============================================================
   WEEK 3 — SYNTHETIC DATA GENERATION
   Domain: Loan Process
   
   This script creates comprehensive test data including:
   ✅ Multiple customers (some with 1 loan, some with multiple)
   ✅ Loans spread across 60-90 days
   ✅ Partial repayments (fully, partially, not repaid)
   ✅ Edge cases:
      - Repayment 45 days after origination
      - Same-day repayment
      - Loan with NO repayment
      - Late-arriving repayment (commented out for later)
   ✅ LATE PAYMENTS (delinquent/overdue with penalty_amount > 0)
   ✅ Loans without repayment (including overdue loans)
============================================================*/


/*============================================================
  1) DIMENSIONS
============================================================*/

-- dim_date: ~90 days so rolling 30-day metrics make sense
;WITH d AS (
    SELECT CAST('2024-01-01' AS date) AS full_date
    UNION ALL
    SELECT DATEADD(day, 1, full_date)
    FROM d
    WHERE full_date < '2024-03-31'
)
INSERT INTO dim_date (date_id, full_date, day, month, year, quarter, is_weekend)
SELECT
    ROW_NUMBER() OVER (ORDER BY full_date)                           AS date_id,
    full_date,
    DATEPART(day, full_date)                                         AS [day],
    DATEPART(month, full_date)                                       AS [month],
    DATEPART(year, full_date)                                        AS [year],
    DATEPART(quarter, full_date)                                     AS [quarter],
    CASE WHEN DATEPART(weekday, full_date) IN (1,7) THEN 1 ELSE 0 END AS is_weekend
FROM d
OPTION (MAXRECURSION 0);


-- dim_customer: multiple customers, some with multiple loans later
INSERT INTO dim_customer (customer_id, full_name, date_of_birth, risk_segment, employment_status,
                          effective_start_date, effective_end_date, is_current)
VALUES
 ('CUST001', 'Alice Johnson',  '1988-03-10', 'Low',    'Employed', '2024-01-01', NULL, 1),
 ('CUST002', 'Bob Smith',      '1985-07-22', 'Medium', 'Employed', '2024-01-01', NULL, 1),
 ('CUST003', 'Carol Brown',    '1990-11-05', 'High',   'Self-Employed', '2024-01-01', NULL, 1),
 ('CUST004', 'David Wilson',   '1979-02-17', 'Low',    'Unemployed', '2024-01-01', NULL, 1),
 ('CUST005', 'Emma Davis',     '1992-05-15', 'Medium', 'Employed', '2024-01-01', NULL, 1);


-- dim_employee: simple set
INSERT INTO dim_employee (employee_code, role, branch, department)
VALUES
 ('EMP001', 'Loan Officer', 'Lagos HQ',      'Retail Lending'),
 ('EMP002', 'Loan Officer', 'London Branch', 'SME Lending'),
 ('EMP003', 'Senior Officer','Remote',       'Digital Lending');


-- dim_medium: channels
INSERT INTO dim_medium (medium_name)
VALUES ('Branch'), ('Web'), ('Mobile');


/*============================================================
  2) FACT_LOAN
     - Customers with 1 vs multiple loans
     - Loans spread across ~75 days
     - Includes loans that will have late payments
     - Includes loans that will have NO repayments
============================================================*/

-- Helper: get IDs from dimension tables
DECLARE @emp1 INT, @emp2 INT, @emp3 INT;
SELECT @emp1 = employee_id FROM dim_employee WHERE employee_code = 'EMP001';
SELECT @emp2 = employee_id FROM dim_employee WHERE employee_code = 'EMP002';
SELECT @emp3 = employee_id FROM dim_employee WHERE employee_code = 'EMP003';

DECLARE @branch_id INT, @web_id INT, @mobile_id INT;
SELECT @branch_id = medium_id FROM dim_medium WHERE medium_name = 'Branch';
SELECT @web_id    = medium_id FROM dim_medium WHERE medium_name = 'Web';
SELECT @mobile_id = medium_id FROM dim_medium WHERE medium_name = 'Mobile';

-- Insert loans (dates chosen to span the range)
INSERT INTO fact_loan (loan_id, customer_id, employee_id, date_id, medium_id,
                       loan_amount, approved_amount, interest_rate, tenure_months)
SELECT 'LOAN001', 'CUST001', @emp1, d.date_id, @branch_id,
       10000,  9500, 0.10, 24
FROM dim_date d WHERE d.full_date = '2024-01-05'

UNION ALL
SELECT 'LOAN002', 'CUST002', @emp1, d.date_id, @web_id,
       20000, 20000, 0.12, 36
FROM dim_date d WHERE d.full_date = '2024-01-10'   -- used for 45-day repayment edge case

UNION ALL
SELECT 'LOAN003', 'CUST002', @emp2, d.date_id, @mobile_id,
       15000, 15000, 0.15, 18
FROM dim_date d WHERE d.full_date = '2024-02-01'

UNION ALL
SELECT 'LOAN004', 'CUST003', @emp2, d.date_id, @branch_id,
       5000,  5000, 0.20, 12
FROM dim_date d WHERE d.full_date = '2024-02-15'

UNION ALL
SELECT 'LOAN005', 'CUST003', @emp3, d.date_id, @web_id,
       30000, 28000, 0.09, 48
FROM dim_date d WHERE d.full_date = '2024-03-01'   -- will have NO repayments (edge case)

UNION ALL
SELECT 'LOAN006', 'CUST004', @emp3, d.date_id, @mobile_id,
       8000,  8000, 0.13, 24
FROM dim_date d WHERE d.full_date = '2024-03-20'

UNION ALL
-- LOAN007: Will have LATE PAYMENTS (delinquent)
SELECT 'LOAN007', 'CUST005', @emp1, d.date_id, @branch_id,
       12000, 12000, 0.14, 12
FROM dim_date d WHERE d.full_date = '2024-01-15'

UNION ALL
-- LOAN008: Will have NO repayments AND is overdue (should have had payments by now)
SELECT 'LOAN008', 'CUST004', @emp2, d.date_id, @web_id,
       15000, 15000, 0.16, 6
FROM dim_date d WHERE d.full_date = '2024-01-20';   -- Originated Jan 20, should have monthly payments by now


/*============================================================
  3) FACT_REPAYMENT
     - Some fully repaid
     - Some partially repaid
     - Some not repaid (LOAN005, LOAN008)
     - Edge cases:
         - 45 days after origination
         - Same-day repayment
         - Loan with no repayment
         - LATE PAYMENTS (with penalty_amount > 0)
     - Late-arriving repayment (separate block)
============================================================*/

-- Main repayments

INSERT INTO fact_repayment (repayment_id, loan_id, date_id, medium_id,
                            repayment_amount, principal_component, interest_component, penalty_amount)

-- LOAN001 (CUST001) – fully repaid on SAME DAY (edge case)
SELECT 'RPY001', 'LOAN001', d.date_id, @branch_id,
       10000, 9500, 500, 0
FROM dim_date d WHERE d.full_date = '2024-01-05'   -- same as origination

UNION ALL
-- LOAN002 (CUST002) – single repayment 45 DAYS AFTER ORIGINATION (edge case)
SELECT 'RPY002', 'LOAN002', d.date_id, @web_id,
       7000, 6500, 500, 0
FROM dim_date d WHERE d.full_date = '2024-02-24'   -- 45 days after 2024-01-10

UNION ALL
-- LOAN003 (CUST002) – PARTIALLY repaid via two installments
SELECT 'RPY003', 'LOAN003', d.date_id, @mobile_id,
       4000, 3500, 500, 0
FROM dim_date d WHERE d.full_date = '2024-02-20'

UNION ALL
SELECT 'RPY004', 'LOAN003', d.date_id, @mobile_id,
       3000, 2500, 500, 0
FROM dim_date d WHERE d.full_date = '2024-03-05'
-- Principal repaid so far = 6000 of 15000 → PARTIAL

UNION ALL
-- LOAN004 (CUST003) – almost fully repaid (still small outstanding)
SELECT 'RPY005', 'LOAN004', d.date_id, @branch_id,
       4500, 4300, 200, 0
FROM dim_date d WHERE d.full_date = '2024-03-10'

UNION ALL
-- LOAN006 (CUST004) – a single partial repayment
SELECT 'RPY006', 'LOAN006', d.date_id, @mobile_id,
       2000, 1800, 200, 0
FROM dim_date d WHERE d.full_date = '2024-03-25'

UNION ALL
-- LOAN007 (CUST005) – LATE PAYMENTS (delinquent with penalties)
-- First payment was due around Feb 15 (30 days after Jan 15), but paid late on Feb 25
SELECT 'RPY007', 'LOAN007', d.date_id, @branch_id,
       1200, 1000, 150, 50    -- penalty_amount = 50 for late payment
FROM dim_date d WHERE d.full_date = '2024-02-25'   -- 10 days late

UNION ALL
-- Second payment for LOAN007: also late (due around March 15, paid March 28)
SELECT 'RPY008', 'LOAN007', d.date_id, @branch_id,
       1200, 1000, 150, 75    -- higher penalty for being later
FROM dim_date d WHERE d.full_date = '2024-03-28'   -- 13 days late

UNION ALL
-- LOAN007: Third payment on time (no penalty)
SELECT 'RPY009', 'LOAN007', d.date_id, @branch_id,
       1200, 1000, 150, 0     -- no penalty, paid on time
FROM dim_date d WHERE d.full_date = '2024-04-15';  -- on time (if date exists in dim_date)

-- NOTE:
-- LOAN005 intentionally has NO rows in fact_repayment to test "no repayment" logic.
-- LOAN008 intentionally has NO rows in fact_repayment AND is overdue (should have had payments by now).


/*============================================================
  4) LATE-ARRIVING REPAYMENT (run later to simulate)
     - Insert this in a separate load or at a later time
     - This simulates data arriving late to the warehouse
============================================================*/

-- Run this block later to simulate a late-arriving event for LOAN004.
-- It uses an earlier repayment date but is loaded after your initial runs.

-- Example: late-arriving repayment that should have been included in an earlier period
-- but only just arrived in the warehouse.

-- Uncomment and run later when you want to test late-arriving logic:

/*
INSERT INTO fact_repayment (repayment_id, loan_id, date_id, medium_id,
                            repayment_amount, principal_component, interest_component, penalty_amount)
SELECT 'RPY010', 'LOAN004', d.date_id, @branch_id,
       800, 700, 100, 0
FROM dim_date d WHERE d.full_date = '2024-02-20';
*/


/*============================================================
  SUMMARY OF DATA CREATED:
  
  ✅ Multiple customers:
     - CUST001: 1 loan (LOAN001)
     - CUST002: 2 loans (LOAN002, LOAN003)
     - CUST003: 2 loans (LOAN004, LOAN005)
     - CUST004: 2 loans (LOAN006, LOAN008)
     - CUST005: 1 loan (LOAN007)
  
  ✅ Loans spread across ~75 days (Jan 5 - Mar 20)
  
  ✅ Repayment scenarios:
     - Fully repaid: LOAN001
     - Partially repaid: LOAN003, LOAN004, LOAN006, LOAN007
     - NOT repaid: LOAN005, LOAN008
  
  ✅ Edge cases:
     - Same-day repayment: LOAN001/RPY001
     - 45-day repayment: LOAN002/RPY002
     - No repayment: LOAN005, LOAN008
     - Late-arriving: RPY010 (commented out)
  
  ✅ LATE PAYMENTS:
     - LOAN007 has 3 repayments:
       * RPY007: late (penalty_amount = 50)
       * RPY008: late (penalty_amount = 75)
       * RPY009: on time (penalty_amount = 0)
  
  ✅ OVERDUE LOANS (no repayment when expected):
     - LOAN008: Originated Jan 20, should have monthly payments by now, but none exist
============================================================*/

