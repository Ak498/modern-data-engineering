fact_loan
  ├─ dim_customer
  ├─ dim_employee
  ├─ dim_date (origination)
  └─ dim_medium

fact_repayment
  ├─ fact_loan (loan_id)
  ├─ dim_date (repayment)
  └─ dim_medium
