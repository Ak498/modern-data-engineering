with latest_daily_balance as (
    select
        date_day,
        outstanding_balance
    from {{ ref('mart_daily_portfolio') }}
    where date_day = (
        select max(date_day)
        from {{ ref('mart_daily_portfolio') }}
    )
),
current_fact_balance as (
    select
        sum(outstanding_balance) as outstanding_balance
    from {{ ref('fct_loan_performance') }}
)

select
    l.date_day,
    l.outstanding_balance as daily_outstanding_balance,
    f.outstanding_balance as fact_outstanding_balance
from latest_daily_balance l
cross join current_fact_balance f
where l.outstanding_balance <> f.outstanding_balance
