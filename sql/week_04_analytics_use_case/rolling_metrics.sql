WITH base AS (
  SELECT
      date_id
    , full_date
    , loans_originated
    , loan_amount_originated
    , repayments_collected
    , principal_collected
    , outstanding_balance
    , active_loans
    , delinquent_loans
  FROM analytics.vw_portfolio_daily
)

SELECT
    full_date

  -- Rolling loan counts
  , SUM(loans_originated) OVER (
        ORDER BY full_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_loans

  , SUM(loans_originated) OVER (
        ORDER BY full_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_loans

  , SUM(loans_originated) OVER (
        ORDER BY full_date
        ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ) AS rolling_90d_loans

  -- Rolling principal collected
  , SUM(principal_collected) OVER (
        ORDER BY full_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_principal

  -- Rolling delinquency rate (weighted)
  , SUM(delinquent_loans) OVER (
        ORDER BY full_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) * 1.0
    /
    NULLIF(
      SUM(active_loans) OVER (
        ORDER BY full_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
      )
    , 0
    ) * 100 AS rolling_30d_delinquency_pct

FROM base;