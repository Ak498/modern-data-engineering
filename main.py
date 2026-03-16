import logging
from pathlib import Path

import yaml

from week_05_python_pipeline.src.ingestion import ingest
from week_05_python_pipeline.src.validation import validate_schema
from week_05_python_pipeline.src.transform import transform_data
from week_05_python_pipeline.src.writer import write_output
from week_05_python_pipeline.src.logging_config import setup_logger
BASE_DIR = Path(__file__).resolve().parent
PIPELINE_DIR = BASE_DIR / "week_05_python_pipeline"
CONFIG_PATH = PIPELINE_DIR / "config.yaml"


def load_config():
    with CONFIG_PATH.open("r", encoding="utf-8") as file:
        config = yaml.safe_load(file)

    for key, value in config["paths"].items():
        config["paths"][key] = (PIPELINE_DIR / value).resolve()

    return config


def main():
    config = load_config()
    setup_logger()
    logger = logging.getLogger("pipeline")

    raw_directory = config["paths"]["raw_directory"]
    file_pattern = config["pipeline"]["file_pattern"]
    csv_files = sorted(raw_directory.glob(file_pattern))

    if not csv_files:
        logger.warning("No CSV files found in %s (pattern=%s)", raw_directory, file_pattern)
        return

    for csv_file in csv_files:
        logger.info("Starting ETL for %s", csv_file.name)
        df = ingest(csv_file)
        df_clean = transform_data(df)
        validate_schema(df_clean)
        write_output(df_clean, config, csv_file.name)
        logger.info("Completed ETL for %s", csv_file.name)

    logger.info("Pipeline completed successfully")

if __name__ == "__main__":
    main()
