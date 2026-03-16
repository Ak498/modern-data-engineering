import pandas as pd


def transform_data(df):

  df = df.copy()

  string_columns = df.select_dtypes(include="object").columns
  for column in string_columns:
    df[column] = df[column].astype("string").str.strip()

  df["loan_id"] = pd.to_numeric(df["loan_id"], errors="coerce")
  df["customer_id"] = pd.to_numeric(df["customer_id"], errors="coerce")
  df["loan_amount"] = pd.to_numeric(
      df["loan_amount"].astype("string").str.replace(r"[^0-9.\-]", "", regex=True),
      errors="coerce"
  )
  df["interest_rate"] = pd.to_numeric(
      df["interest_rate"].astype("string").str.replace("%", "", regex=False),
      errors="coerce"
  )

  df["origination_date"] = pd.to_datetime(df["origination_date"], errors="coerce")
  df["load_timestamp"] = pd.to_datetime(df["load_timestamp"], errors="coerce")

  df = df.dropna(subset=["loan_id", "loan_amount"])
  df = df[df["loan_amount"] > 0]
  df = df.drop_duplicates(subset=["loan_id"])

  return df
