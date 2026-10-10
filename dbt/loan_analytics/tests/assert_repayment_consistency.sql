with repayment_summary as (
    select
        loan_id,
        sum(repayment_amount) as total_repayment_amount,
        sum(principal_component) as total_principal_component,
        sum(interest_component) as total_interest_component,
        sum(penalty_amount) as total_penalty_amount
    from {{ ref('stg_repayments') }}
    group by 1
)

select
    loan_id,
    total_repayment_amount,
    total_principal_component + total_interest_component + total_penalty_amount as expected_total
from repayment_summary
where abs(total_repayment_amount - (total_principal_component + total_interest_component + total_penalty_amount)) > 0.01
