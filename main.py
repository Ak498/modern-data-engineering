import logging
from src.ingestion import ingest
from validate import validate_schema
from transform import transform_data
from writer import write_parquet
from logging_config import setup_logger

logger = logging.getLogger(__name__)

def main():

  df = ingest(file_path)

  validate_schema(df)

  df_clean = transform_data(df)

  write_parquet(df_clean, config)

  logger.info("Pipeline completed successfully")


if __name__ == "__main__":
    main()
