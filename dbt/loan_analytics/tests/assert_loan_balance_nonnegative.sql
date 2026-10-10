select
    loan_id,
    loan_amount,
    principal_repaid,
    outstanding_balance
from {{ ref('fct_loan_performance') }}
where principal_repaid > loan_amount
