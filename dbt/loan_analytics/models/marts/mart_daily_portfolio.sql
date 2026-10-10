with loans as (
    select * from {{ ref('stg_loans') }}
),
repayments as (
    select * from {{ ref('stg_repayments') }}
),
originations_daily as (
    select
        cast(origination_date as date) as date_day,
        count(*) as loans_originated,
        sum(loan_amount) as total_loan_amount
    from loans
    group by 1
),
repayments_daily as (
    select
        cast(payment_date as date) as date_day,
        sum(repayment_amount) as total_repayments,
        sum(principal_component) as principal_collected
    from repayments
    group by 1
),
date_bounds as (
    select
        min(date_day) as first_day,
        max(date_day) as last_day
    from (
        select cast(origination_date as date) as date_day from loans
        union all
        select cast(payment_date as date) as date_day from repayments
    )
),
date_spine as (
    select cast(d as date) as date_day
    from generate_series(
        (select first_day from date_bounds),
        (select last_day from date_bounds),
        interval 1 day
    ) as t(d)
),
portfolio_daily as (
    select
        ds.date_day,
        coalesce(od.loans_originated, 0) as loans_originated,
        coalesce(od.total_loan_amount, 0) as total_loan_amount,
        coalesce(rd.total_repayments, 0) as total_repayments,
        coalesce(rd.principal_collected, 0) as principal_collected,
        sum(
            coalesce(od.total_loan_amount, 0) - coalesce(rd.principal_collected, 0)
        ) over (
            order by ds.date_day
            rows between unbounded preceding and current row
        ) as outstanding_balance
    from date_spine ds
    left join originations_daily od on ds.date_day = od.date_day
    left join repayments_daily rd on ds.date_day = rd.date_day
)

select
    date_day,
    loans_originated,
    total_loan_amount,
    total_repayments,
    principal_collected,
    outstanding_balance
from portfolio_daily
order by date_day
