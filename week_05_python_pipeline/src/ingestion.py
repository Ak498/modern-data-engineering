import os
import sys
import logging
import time
import json 

import pandas as pd
import yaml

logger = logging.getLogger(__name__)

# read config.yaml
with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)
    raw_directory = config['paths']['raw_directory']

# ingest data from a source
def ingest(raw_directory: str) -> dict:
    """
    Reads all CSV files in a specified directory and loads each into a pandas DataFrame.
    Args:
        raw_directory: The path to the directory containing CSV files.
    Returns:
        A dictionary where keys are file names and values are pandas DataFrames containing the data.
    """
    logger.info(f'Ingesting all CSV files from directory: {raw_directory}')
    dataframes = {}
    try:
        for filename in os.listdir(raw_directory):
            if filename.lower().endswith('.csv'):
                file_path = os.path.join(raw_directory, filename)
                logger.info(f'Ingesting data from {file_path}')
                try:
                    df = pd.read_csv(file_path)
                    dataframes[filename] = df
                    logger.info(f'Data ingested successfully from {file_path}')
                except Exception as e_file:
                    logger.error(f'Error ingesting data from {file_path}: {e_file}')
        return dataframes
    except Exception as e:
        logger.error(f'Error accessing directory {raw_directory}: {e}')
        raise e


