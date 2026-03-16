import pandas as pd


def validate_schema(df):

  required_cols = [
    "loan_id",
    "customer_id",
    "loan_amount",
    "interest_rate"
  ]

  missing = set(required_cols) - set(df.columns)

  if missing:
      raise ValueError("Missing required columns")

  if df.empty:
    raise ValueError("No valid rows available after cleaning")

  if df["loan_id"].isna().any():
    raise ValueError("Missing loan_id detected")

  loan_amount = pd.to_numeric(df["loan_amount"], errors="coerce")

  if loan_amount.isna().any():
    raise ValueError("Invalid loan amount detected")

  if loan_amount.le(0).any():
    raise ValueError("Invalid loan amount detected")

  interest_rate = pd.to_numeric(df["interest_rate"], errors="coerce")

  if interest_rate.notna().any() and interest_rate.lt(0).any():
    raise ValueError("Invalid interest rate detected")
