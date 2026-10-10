with loans as (
    select * from {{ ref('stg_loans') }}
),
repayments as (
    select * from {{ ref('stg_repayments') }}
),
loan_rollup as (
    select
        l.loan_id,
        l.customer_id,
        l.origination_date,
        l.loan_amount,
        count(r.repayment_id) as repayment_count,
        coalesce(sum(r.repayment_amount), 0) as total_repayments,
        coalesce(sum(r.principal_component), 0) as principal_repaid,
        coalesce(sum(r.interest_component), 0) as interest_paid,
        coalesce(sum(r.penalty_amount), 0) as total_penalties,
        l.loan_amount - coalesce(sum(r.principal_component), 0) as outstanding_balance,
        greatest(coalesce(sum(r.principal_component), 0) - l.loan_amount, 0) as over_repaid_amount
    from loans l
    left join repayments r
        on r.loan_id = l.loan_id
    group by
        l.loan_id,
        l.customer_id,
        l.origination_date,
        l.loan_amount
)

select * from loan_rollup
