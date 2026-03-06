import logging
from week_05_python_pipelinesrc.ingestion import ingest
from week_05_python_pipeline.src. validate import validate_schema
from week_05_python_pipeline.src.transform import transform_data
from week_05_python_pipeline.src.writer import write_parquet
from week_05_python_pipeline.src.logging_config import setup_logger
import yaml
import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

logger = logging.getLogger(__name__)

# read config.yaml
with open(os.path.join(os.path.dirname(__file__), 'week_05_python_pipeline', 'config.yaml'), 'r') as f:
    config = yaml.safe_load(f)
    raw_directory = config['paths']['raw_directory']

def main():

  df_dict = ingest(raw_directory)

  for df in df_dict.values(): # validate each dataframe in the dictionary 
    validate_schema(df) # validate the schema of the dataframe
    df_clean = transform_data(df) # transform the dataframe
    # df_clean = validate_data(df_clean) # validate the data of the dataframe
    write_parquet(df_clean, config)
  # archive_data(df_dict) # archive the data    
    
  logger.info("Pipeline completed successfully")

if __name__ == "__main__":
    main()
