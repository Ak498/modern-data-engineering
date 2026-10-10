with loan_summary as (
    select * from {{ ref('int_loan_summary') }}
)

select
    loan_id,
    customer_id,
    origination_date,
    loan_amount,
    principal_repaid,
    total_repayments,
    total_penalties,
    outstanding_balance,
    over_repaid_amount
from loan_summary
