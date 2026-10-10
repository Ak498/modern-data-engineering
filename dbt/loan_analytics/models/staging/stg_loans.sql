with source as (

    select * from {{ ref('loans') }}

)

select
    loan_id,
    customer_id,
    cast(origination_date as date) as origination_date,
    cast(loan_amount as numeric(18,2)) as loan_amount,
    cast(interest_rate as numeric(18,6)) as interest_rate,
    cast(tenure_months as integer) as tenure_months,
    cast(employee_id as string) as employee_id,
    cast(medium_id as string) as medium_id
from source
