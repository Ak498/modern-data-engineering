
/*
  Model: analytics.vw_portfolio_daily
  Grain: 1 row per calendar date

  Rules enforced:
  1) Aggregate first, then join (prevents loan amount multiplication)
  2) Percentages use numerator * 1.0 / NULLIF(denominator, 0) * 100
*/

CREATE OR ALTER VIEW analytics.vw_portfolio_daily
AS
WITH loan_base AS (
    SELECT
          fl.loan_id
        , dd.date_id AS origination_date_id
        , dd.full_date AS origination_date
        , fl.loan_amount
    FROM fact_loan AS fl
    JOIN dim_date AS dd
        ON fl.date_id = dd.date_id
),
repayment_base AS (
    SELECT
          fr.loan_id
        , dd.date_id AS repayment_date_id
        , dd.full_date AS repayment_date
        , fr.repayment_amount
        , fr.principal_component
    FROM fact_repayment AS fr
    JOIN dim_date AS dd
        ON fr.date_id = dd.date_id
),
calendar AS (
    SELECT
          d.date_id
        , d.full_date
    FROM dim_date AS d
    WHERE d.full_date >= (SELECT MIN(origination_date) FROM loan_base)
      AND d.full_date <= CAST(GETDATE() AS DATE)
),
originations_daily AS (
    SELECT
          lb.origination_date_id AS date_id
        , COUNT(DISTINCT lb.loan_id) AS loans_originated
        , SUM(lb.loan_amount) AS loan_amount_originated
    FROM loan_base AS lb
    GROUP BY
        lb.origination_date_id
),
repayments_daily AS (
    SELECT
          rb.repayment_date_id AS date_id
        , SUM(rb.repayment_amount) AS repayments_collected
        , SUM(rb.principal_component) AS principal_collected
    FROM repayment_base AS rb
    GROUP BY
        rb.repayment_date_id
),
repayment_daily_by_loan AS (
    SELECT
          rb.loan_id
        , rb.repayment_date_id AS date_id
        , SUM(rb.principal_component) AS principal_collected_loan_day
    FROM repayment_base AS rb
    GROUP BY
          rb.loan_id
        , rb.repayment_date_id
),
loan_calendar AS (
    SELECT
          c.date_id
        , c.full_date
        , lb.loan_id
        , lb.loan_amount
        , lb.origination_date
    FROM calendar AS c
    JOIN loan_base AS lb
        ON lb.origination_date <= c.full_date
),
loan_state_daily AS (
    SELECT
          lc.date_id
        , lc.full_date
        , lc.loan_id
        , lc.loan_amount
        , lc.origination_date
        , COALESCE(rdl.principal_collected_loan_day, 0.0) AS principal_collected_loan_day
        , SUM(COALESCE(rdl.principal_collected_loan_day, 0.0)) OVER (
              PARTITION BY lc.loan_id
              ORDER BY lc.full_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS principal_collected_to_date
        , MAX(CASE WHEN rdl.principal_collected_loan_day IS NOT NULL THEN lc.full_date END) OVER (
              PARTITION BY lc.loan_id
              ORDER BY lc.full_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS last_repayment_date_to_date
    FROM loan_calendar AS lc
    LEFT JOIN repayment_daily_by_loan AS rdl
        ON lc.loan_id = rdl.loan_id
       AND lc.date_id = rdl.date_id
),
portfolio_state_daily AS (
    SELECT
          lsd.date_id
        , SUM(lsd.loan_amount - lsd.principal_collected_to_date) AS outstanding_balance
        , COUNT(DISTINCT CASE
              WHEN lsd.loan_amount - lsd.principal_collected_to_date > 0 THEN lsd.loan_id
          END) AS active_loans
        , COUNT(DISTINCT CASE
              WHEN lsd.loan_amount - lsd.principal_collected_to_date > 0
               AND COALESCE(lsd.last_repayment_date_to_date, lsd.origination_date) < DATEADD(DAY, -90, lsd.full_date)
              THEN lsd.loan_id
          END) AS delinquent_loans
    FROM loan_state_daily AS lsd
    GROUP BY
        lsd.date_id
),
portfolio_with_pct AS (
    SELECT
          psd.date_id
        , psd.outstanding_balance
        , psd.active_loans
        , psd.delinquent_loans
        , psd.delinquent_loans * 1.0 / NULLIF(psd.active_loans, 0) * 100 AS delinquency_rate_pct
    FROM portfolio_state_daily AS psd
),
daily_base AS (
    SELECT
          c.date_id
        , c.full_date
        , COALESCE(od.loans_originated, 0) AS loans_originated
        , COALESCE(od.loan_amount_originated, 0.0) AS loan_amount_originated
        , COALESCE(rd.repayments_collected, 0.0) AS repayments_collected
        , COALESCE(rd.principal_collected, 0.0) AS principal_collected
        , COALESCE(pwp.outstanding_balance, 0.0) AS outstanding_balance
        , COALESCE(pwp.active_loans, 0) AS active_loans
        , COALESCE(pwp.delinquent_loans, 0) AS delinquent_loans
        , COALESCE(pwp.delinquency_rate_pct, 0.0) AS delinquency_rate_pct
    FROM calendar AS c
    LEFT JOIN originations_daily AS od
        ON c.date_id = od.date_id
    LEFT JOIN repayments_daily AS rd
        ON c.date_id = rd.date_id
    LEFT JOIN portfolio_with_pct AS pwp
        ON c.date_id = pwp.date_id
)
SELECT
      db.date_id
    , db.full_date
    , db.loans_originated
    , db.loan_amount_originated
    , db.repayments_collected
    , db.principal_collected
    , db.outstanding_balance
    , db.active_loans
    , db.delinquent_loans
    , db.delinquency_rate_pct
    , db.repayments_collected * 1.0 / NULLIF(db.loan_amount_originated, 0.0) * 100 AS same_day_collection_rate_pct
FROM daily_base AS db;

