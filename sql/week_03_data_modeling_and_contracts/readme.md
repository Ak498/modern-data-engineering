## Week 03 — Data Modeling and Contracts (Loan Domain)

This folder contains the dimensional model, data quality validations, and contracts for a simple loan-processing analytics mart.  
The design follows a **star schema** with conformed dimensions and fact tables for loans and repayments.

### Contents

- **`dimensional_model.sql`**: DDL for all dimension and fact tables.
- **`ER diagram.md`**: Text ER description of table relationships.
- **`validations/`**: SQL checks for constraints, SLAs, and data quality.
- **`contracts/`**: YAML contracts that formalize expectations on fact tables.

### Dimensional Model Overview

- **Dimensions**
  - `dim_customer`: Customer attributes, risk segment, SCD fields (`effective_start_date`, `effective_end_date`, `is_current`).
  - `dim_employee`: Staff responsible for loan origination (role, branch, department).
  - `dim_date`: Calendar dimension keyed by `date_id` (day, month, year, quarter, weekend flag).
  - `dim_medium`: Channel/medium used (e.g. branch, mobile, web).

-- **Facts**
  - `fact_loan`
    - Grain: **one row per loan_id**.
    - Keys: `loan_id`, `customer_id`, `employee_id`, `date_id`, `medium_id`.
    - Measures: `loan_amount`, `approved_amount`, `interest_rate`, `tenure_months`.
  - `fact_repayment`
    - Grain: **one row per repayment_id**.
    - Keys: `repayment_id`, `loan_id`, `date_id`, `medium_id`.
    - Measures: `repayment_amount`, `principal_component`, `interest_component`, `penalty_amount`.

Foreign keys enforce integrity between facts and dimensions (e.g. loans to customers and employees, repayments to loans and dates).

### Validations (`validations/`)

Each SQL file is intended to be run against the analytical database; **any returned rows indicate a violation**.

- **`domain_constraint.sql`**: Ensures interest rate is between 0 and 1, and tenure is positive.
- **`financial_consistency_checks.sql`**:
  - `repayment_amount = principal_component + interest_component + penalty_amount`.
  - Cumulative principal repaid does not exceed the original `loan_amount`.
- **`grain_checks.sql`**: Checks for duplicate `loan_id` in `fact_loan` and duplicate `repayment_id` in `fact_repayment`.
- **`null_check.sql`**: Flags missing critical fields such as `loan_amount` and `customer_id`.
- **`risk_segment_enforcement.sql`**: Verifies `risk_segment` values are within the allowed set (`Low`, `Medium`, `High`).
- **`scd_validation.sql`**: Looks for overlapping effective periods in `dim_customer` SCD records.
- **`sla_checks.sql`**: Simple SLA check using the max `date_id` in `fact_loan` as a proxy for data freshness.
- **`temporal_checks.sql`**: Ensures repayment `date_id` is not earlier than the corresponding loan date.
- **`referential_integrity_checks.sql`**: Placeholder for additional cross-table integrity checks.

### Contracts (`contracts/`)

The YAML files in `contracts/` describe expectations for downstream consumers (e.g. BI, ML):

- **`fact_loan_contract.yaml`**: Contract for the loan fact table (schema, key, and quality expectations).
- **`fact_repayment_contract.yaml`**: Contract for the repayment fact table.

These can be used by orchestration/testing tools to automatically verify that new data loads meet agreed standards.

### How to Use

- **Create schema**
  - Run `dimensional_model.sql` in your target database (e.g. SQL Server, Postgres with minor syntax tweaks).
- **Run data quality checks**
  - After loading data into the tables, execute each SQL file in `validations/`.
  - Investigate and fix any rows returned by these queries before publishing data to consumers.
- **Evolve contracts**
  - Update the YAML contracts as new columns, constraints, or SLAs are agreed with stakeholders.

This module is designed as a teaching artifact for **modern data engineering** concepts: dimensional modeling, data contracts, and automated validations.
