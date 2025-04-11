# -----------------------------------------------
# Import required modules
# -----------------------------------------------
import airflow
from airflow import DAG
from datetime import timedelta
from airflow.utils.dates import days_ago
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

# -----------------------------------------------
# Constants for GCP and SQL paths
# -----------------------------------------------
PROJECT_ID = "omega-art-450811-b0"  # Your GCP project ID
LOCATION = "US"                     # BigQuery dataset location

# Paths to the SQL transformation scripts stored in Cloud Composer's bucket
SQL_FILE_PATH_1 = "/home/airflow/gcs/data/BQ/bronzeTable.sql"
SQL_FILE_PATH_2 = "/home/airflow/gcs/data/BQ/silverTable.sql"
SQL_FILE_PATH_3 = "/home/airflow/gcs/data/BQ/goldTable.sql"

# -----------------------------------------------
# Function to read SQL content from file
# -----------------------------------------------
def read_sql_file(file_path):
    """Reads the SQL file content from GCS file system."""
    with open(file_path, "r") as file:
        return file.read()

# Read and store SQL queries into Python variables
BRONZE_QUERY = read_sql_file(SQL_FILE_PATH_1)
SILVER_QUERY = read_sql_file(SQL_FILE_PATH_2)
GOLD_QUERY = read_sql_file(SQL_FILE_PATH_3)

# -----------------------------------------------
# Default arguments used by all tasks in the DAG
# -----------------------------------------------
ARGS = {
    "owner": "SWAPNIL GAIKWAD",
    "start_date": None,                          # Manual/triggered DAG
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "email": ["***@gmail.com"],
    "email_on_success": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

# -----------------------------------------------
# Define the DAG
# -----------------------------------------------
with DAG(
    dag_id="bigquery_dag",
    schedule_interval=None,                    # Only triggered manually or via parent DAG
    description="DAG to run the bigquery jobs",
    default_args=ARGS,
    tags=["gcs", "bq", "etl", "marvel"]
) as dag:

    # -----------------------------------------------
    # Task 1: Run Bronze SQL - Raw data cleaning/loading
    # -----------------------------------------------
    bronze_tables = BigQueryInsertJobOperator(
        task_id="bronze_tables",
        configuration={
            "query": {
                "query": BRONZE_QUERY,        # Executes the SQL read from bronzeTable.sql
                "useLegacySql": False,
                "priority": "BATCH",          # Cost-effective execution
            }
        },
    )

    # -----------------------------------------------
    # Task 2: Run Silver SQL - Data enrichment/transformation
    # -----------------------------------------------
    silver_tables = BigQueryInsertJobOperator(
        task_id="silver_tables",
        configuration={
            "query": {
                "query": SILVER_QUERY,        # Executes the SQL read from silverTable.sql
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
    )

    # -----------------------------------------------
    # Task 3: Run Gold SQL - Final reporting-ready tables
    # -----------------------------------------------
    gold_tables = BigQueryInsertJobOperator(
        task_id="gold_tables",
        configuration={
            "query": {
                "query": GOLD_QUERY,          # Executes the SQL read from goldTable.sql
                "useLegacySql": False,
                "priority": "BATCH",
            }
        },
    )


# -----------------------------------------------
# Define Task Execution Order
# Bronze → Silver → Gold
# -----------------------------------------------
bronze_tables >> silver_tables >> gold_tables