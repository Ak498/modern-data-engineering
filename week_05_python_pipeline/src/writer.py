from pathlib import Path


def write_output(df, config, source_file_name):

  output_dir = Path(config["paths"]["processed_directory"])
  output_dir.mkdir(parents=True, exist_ok=True)
  output_file = output_dir / f"{Path(source_file_name).stem}.parquet"

  df.to_parquet(
      output_file,
      index=False
  )
