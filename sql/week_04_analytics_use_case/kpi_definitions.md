# KPI Definitions — Loan Portfolio Analytics

This document defines the Key Performance Indicators (KPIs) for the loan portfolio analytics use case. All metrics support **rolling windows** (7-day, 30-day, 90-day) and handle **late-arriving data**.

---

## 📊 PORTFOLIO HEALTH KPIs

### 1. Total Loan Originations
**Definition:** Count of loans originated in the period  
**Formula:** `COUNT(DISTINCT loan_id) WHERE origination_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Track loan volume trends

### 2. Total Loan Amount Originated
**Definition:** Sum of `loan_amount` for loans originated in the period  
**Formula:** `SUM(loan_amount) WHERE origination_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Measure portfolio growth in monetary terms

### 3. Average Loan Size
**Definition:** Mean `loan_amount` for loans originated in the period  
**Formula:** `AVG(loan_amount) WHERE origination_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Understand customer segment preferences

### 4. Outstanding Loan Balance
**Definition:** Total principal remaining across all active loans  
**Formula:** `SUM(loan_amount) - SUM(principal_component)`  
**Calculation:** `loan_amount - cumulative_principal_repaid`  
**Business Use:** Current portfolio exposure

### 5. Portfolio Size (Active Loans)
**Definition:** Count of loans that are not fully repaid  
**Formula:** `COUNT(DISTINCT loan_id) WHERE cumulative_principal < loan_amount`  
**Business Use:** Active loan count

---

## 💰 FINANCIAL PERFORMANCE KPIs

### 6. Total Repayments Collected
**Definition:** Sum of `repayment_amount` in the period  
**Formula:** `SUM(repayment_amount) WHERE repayment_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Cash flow tracking

### 7. Principal Collected
**Definition:** Sum of `principal_component` in the period  
**Formula:** `SUM(principal_component) WHERE repayment_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Principal recovery rate

### 8. Interest Collected
**Definition:** Sum of `interest_component` in the period  
**Formula:** `SUM(interest_component) WHERE repayment_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Revenue from interest

### 9. Penalty Revenue
**Definition:** Sum of `penalty_amount` collected in the period  
**Formula:** `SUM(penalty_amount) WHERE repayment_date IN period`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Revenue from late payment penalties

### 10. Collection Rate
**Definition:** Percentage of expected repayments actually collected  
**Formula:** `(actual_repayments / expected_repayments) * 100`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Overall repayment performance

---

## ⚠️ RISK & DELINQUENCY KPIs

### 11. Delinquency Rate
**Definition:** Percentage of loans with overdue payments  
**Formula:** `(loans_with_overdue_payments / total_active_loans) * 100`  
**Calculation:** Loans where `expected_payment_date < today` AND `no_payment_exists`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Portfolio risk assessment

### 12. Late Payment Rate
**Definition:** Percentage of repayments that were late  
**Formula:** `(late_payments / total_payments) * 100`  
**Calculation:** Payments where `penalty_amount > 0` OR `payment_date > expected_date + grace_period`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Payment behavior tracking

### 13. Average Days Past Due (DPD)
**Definition:** Mean number of days payments are overdue  
**Formula:** `AVG(DATEDIFF(day, expected_payment_date, actual_payment_date)) WHERE late`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Severity of delinquency

### 14. Non-Performing Loans (NPL) Rate
**Definition:** Percentage of loans with no payments for 90+ days  
**Formula:** `(NPL_count / total_active_loans) * 100`  
**Calculation:** Loans where `last_payment_date < today - 90 days` OR `no_payments_exist AND origination_date < today - 90 days`  
**Business Use:** Critical risk indicator

### 15. At-Risk Loans
**Definition:** Count of loans with overdue payments  
**Formula:** `COUNT(DISTINCT loan_id) WHERE has_overdue_payment = TRUE`  
**Business Use:** Early warning indicator

---

## 📈 OPERATIONAL KPIs

### 16. Loans by Channel (Medium)
**Definition:** Loan origination count grouped by `medium_id`  
**Formula:** `COUNT(DISTINCT loan_id) GROUP BY medium_name`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Channel performance comparison

### 17. Loans by Employee
**Definition:** Loan origination count grouped by `employee_id`  
**Formula:** `COUNT(DISTINCT loan_id) GROUP BY employee_code, branch`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Employee performance tracking

### 18. Loans by Branch
**Definition:** Loan origination count grouped by branch  
**Formula:** `COUNT(DISTINCT loan_id) GROUP BY branch`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Branch performance comparison

### 19. Loans by Risk Segment
**Definition:** Loan count grouped by customer `risk_segment`  
**Formula:** `COUNT(DISTINCT loan_id) GROUP BY risk_segment`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Risk distribution analysis

### 20. Average Interest Rate by Segment
**Definition:** Mean `interest_rate` grouped by `risk_segment`  
**Formula:** `AVG(interest_rate) GROUP BY risk_segment`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Pricing strategy validation

---

## 🔄 REPAYMENT BEHAVIOR KPIs

### 21. Repayment Rate
**Definition:** Percentage of loans with at least one repayment  
**Formula:** `(loans_with_repayments / total_loans) * 100`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Customer engagement metric

### 22. Full Repayment Rate
**Definition:** Percentage of loans fully repaid  
**Formula:** `(fully_repaid_loans / total_loans) * 100`  
**Calculation:** Loans where `SUM(principal_component) >= loan_amount`  
**Rolling Windows:** 90d, 180d  
**Business Use:** Completion rate

### 23. Partial Repayment Rate
**Definition:** Percentage of loans with partial repayments  
**Formula:** `(partially_repaid_loans / total_loans) * 100`  
**Calculation:** Loans where `0 < SUM(principal_component) < loan_amount`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Payment behavior insight

### 24. Average Repayment Amount
**Definition:** Mean `repayment_amount` per transaction  
**Formula:** `AVG(repayment_amount)`  
**Rolling Windows:** 7d, 30d, 90d  
**Business Use:** Payment size trends

### 25. Repayment Frequency
**Definition:** Average number of repayments per loan  
**Formula:** `AVG(repayment_count_per_loan)`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Payment pattern analysis

---

## 📅 TIME-BASED KPIs (Rolling Windows)

### 26. Rolling 7-Day Loan Originations
**Definition:** Loans originated in the last 7 days  
**Formula:** `COUNT(DISTINCT loan_id) WHERE origination_date >= today - 7 days`  
**Business Use:** Short-term trend monitoring

### 27. Rolling 30-Day Loan Originations
**Definition:** Loans originated in the last 30 days  
**Formula:** `COUNT(DISTINCT loan_id) WHERE origination_date >= today - 30 days`  
**Business Use:** Monthly performance tracking

### 28. Rolling 90-Day Loan Originations
**Definition:** Loans originated in the last 90 days  
**Formula:** `COUNT(DISTINCT loan_id) WHERE origination_date >= today - 90 days`  
**Business Use:** Quarterly trend analysis

### 29. Rolling 30-Day Repayment Collection
**Definition:** Total repayments collected in the last 30 days  
**Formula:** `SUM(repayment_amount) WHERE repayment_date >= today - 30 days`  
**Business Use:** Monthly cash flow

### 30. Rolling 7-Day Delinquency Rate
**Definition:** Delinquency rate calculated over the last 7 days  
**Formula:** `(new_delinquencies_last_7d / active_loans_last_7d) * 100`  
**Business Use:** Early warning system

---

## 🎯 CUSTOMER KPIs

### 31. Average Loans per Customer
**Definition:** Mean number of loans per customer  
**Formula:** `AVG(loan_count_per_customer)`  
**Rolling Windows:** 30d, 90d  
**Business Use:** Customer loyalty/retention

### 32. Repeat Customer Rate
**Definition:** Percentage of customers with multiple loans  
**Formula:** `(customers_with_multiple_loans / total_customers) * 100`  
**Rolling Windows:** 90d, 180d  
**Business Use:** Customer retention metric

### 33. Customer Lifetime Value (CLV)
**Definition:** Total revenue (interest + penalties) per customer  
**Formula:** `SUM(interest_component + penalty_amount) GROUP BY customer_id`  
**Business Use:** Customer profitability

---

## 📋 DATA QUALITY & COMPLETENESS KPIs

### 34. Data Freshness (SLA)
**Definition:** Days since last loan origination  
**Formula:** `DATEDIFF(day, MAX(origination_date), today)`  
**Business Use:** Data pipeline health check

### 35. Late-Arriving Data Impact
**Definition:** Count of repayments loaded after their expected period  
**Formula:** `COUNT(*) WHERE repayment_date < load_date - 1 day`  
**Business Use:** Data quality monitoring

### 36. Missing Payment Records
**Definition:** Count of expected payments with no corresponding record  
**Formula:** `COUNT(*) WHERE expected_payment_date < today AND no_payment_exists`  
**Business Use:** Data completeness check

---

## 🔧 CALCULATION NOTES

### Rolling Window Implementation
- Use `DATEADD(day, -N, GETDATE())` for N-day windows
- Filter by `origination_date` or `repayment_date` accordingly
- Use window functions (`SUM() OVER()`, `COUNT() OVER()`) for cumulative metrics

### Late-Arriving Data Handling
- Use `AS OF` timestamp or `load_date` column if available
- Recalculate metrics when late data arrives
- Document data cutoff times in reports

### Edge Cases
- Loans with no repayments: Use `LEFT JOIN` and `IS NULL` checks
- Same-day repayments: Handle in date comparisons
- Partial repayments: Compare `SUM(principal_component)` vs `loan_amount`

---

## 📊 RECOMMENDED DASHBOARD LAYOUT

### Executive Dashboard
- Total Loan Originations (30d)
- Outstanding Loan Balance
- Delinquency Rate
- Collection Rate

### Operational Dashboard
- Loans by Channel (30d)
- Loans by Branch (30d)
- Late Payment Rate (30d)
- Average Days Past Due

### Risk Dashboard
- Non-Performing Loans Rate
- At-Risk Loans Count
- Delinquency Rate by Risk Segment
- Average DPD by Branch

### Financial Dashboard
- Total Repayments Collected (30d)
- Interest Collected (30d)
- Penalty Revenue (30d)
- Collection Rate (30d)

---

## ✅ VALIDATION QUERIES

Each KPI should be validated with:
1. **Null checks:** Ensure no NULL values break calculations
2. **Boundary checks:** Verify metrics are within expected ranges
3. **Consistency checks:** Cross-validate related metrics
4. **Historical comparison:** Compare against previous periods

---

**Last Updated:** 2024  
**Data Coverage:** 2024-01-05 to 2024-03-20  
**Rolling Windows Supported:** 7d, 30d, 90d

