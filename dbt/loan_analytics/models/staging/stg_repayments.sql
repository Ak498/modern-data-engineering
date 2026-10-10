with source as (

    select * from {{ ref('repayments') }}

)

select
    repayment_id,
    loan_id,
    cast(payment_date as date) as payment_date,
    cast(repayment_amount as numeric(18,2)) as repayment_amount,
    cast(principal_component as numeric(18,2)) as principal_component,
    cast(interest_component as numeric(18,2)) as interest_component,
    cast(penalty_amount as numeric(18,2)) as penalty_amount
from source
