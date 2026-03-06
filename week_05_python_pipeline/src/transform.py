def transform_data(df):

  df["loan_amount"] = df["loan_amount"].astype(float)

  df = df.drop_duplicates(subset=["loan_id"])

  df = df[df["loan_amount"] > 0]

  return df