import logging
from pathlib import Path

import pandas as pd

logger = logging.getLogger(__name__)

def ingest(file_path: str | Path) -> pd.DataFrame:
    """
    Reads a single CSV file into a pandas DataFrame.

    Args:
        file_path: The path to the CSV file.

    Returns:
        A pandas DataFrame containing the file data.
    """
    csv_path = Path(file_path)

    if csv_path.suffix.lower() != ".csv":
        raise ValueError(f"Expected a CSV file, got: {csv_path}")

    if not csv_path.exists():
        raise FileNotFoundError(f"Input file not found: {csv_path}")

    logger.info("Ingesting data from %s", csv_path)

    try:
        df = pd.read_csv(csv_path)
        logger.info("Data ingested successfully from %s", csv_path)
        return df
    except Exception as e:
        logger.error("Error ingesting data from %s: %s", csv_path, e)
        raise
