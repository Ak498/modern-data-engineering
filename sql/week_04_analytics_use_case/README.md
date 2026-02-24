What date range does the seed data cover?
It covers data from 2024-01-05 to 2024-03-20

How many loans?
There are 6 loans applied for.

How many repayments?
There are 5 repayments

Are there partial repayments?
Yes, there are 

Are there late repayments?
Yes, there are

Are there loans with no repayments?
Yes, there is a loan with no repayment yet

Delinquency definition used in Week 04 analytics model
This model uses a behavioral definition, not contractual delinquency.

Delinquent loan (behavioral)
A loan is flagged delinquent when:
- it is still active (outstanding principal > 0), and
- it has no repayment activity in the last 90 days.

Important assumption
This definition assumes repayment activity is expected at least once within 90 days.
For products like bullet loans, this can misclassify loans as delinquent.

Performance note on daily loan expansion
The `loan_calendar` step expands loans to one row per loan per day from origination to the as-of date.

Why this can be expensive
- 100,000 loans across 365 days can produce about 36.5 million rows.
- 1,000,000 loans across multiple years can become very large.

Status for this project
This is acceptable for learning and for small datasets in Week 04.

Production considerations
In production, this pattern is usually optimized by:
- partitioning by date,
- incremental materialization, and
- using periodic snapshots where appropriate.
