with loan_summary as (
    select * from {{ ref('int_loan_summary') }}
)

select
    count(*) as total_loans,
    sum(loan_amount) as total_loan_amount_originated,
    avg(loan_amount) as average_loan_size,
    sum(total_repayments) as total_repayments_collected,
    sum(principal_repaid) as total_principal_repaid,
    sum(total_penalties) as total_penalties_collected,
    sum(outstanding_balance) as outstanding_balance,
    count(*) filter (where outstanding_balance > 0) as active_loans,
    count(*) filter (where outstanding_balance > 0 and repayment_count = 0) as loans_without_repayments
from loan_summary
