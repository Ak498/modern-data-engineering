def write_output(df, config):

  output_dir = config["paths"]["processed_dir"]

  df.to_parquet(
      f"{output_dir}/loans.parquet",
      index=False
  )