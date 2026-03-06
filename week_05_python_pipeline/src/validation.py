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

  if df["loan_amount"].le(0).any():
    raise ValueError("Invalid loan amount detected")