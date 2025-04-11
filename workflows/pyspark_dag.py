# -----------------------------------------------
# Import required modules from Airflow and Dataproc
# -----------------------------------------------
import airflow
from airflow import DAG
from datetime import timedelta
from airflow.utils.dates import days_ago
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocStartClusterOperator,
    DataprocStopClusterOperator,
    DataprocSubmitJobOperator,
)

# -----------------------------------------------
# GCP and cluster configuration variables
# -----------------------------------------------
PROJECT_ID = "omega-art-450811-b0"                      # GCP project ID
REGION = "us-east1"                                     # Region where Dataproc is deployed
CLUSTER_NAME = "retail-datalake-project-cluster"                        # Name of the Dataproc cluster
COMPOSER_BUCKET = "us-east1-composerenvswap-b2e75f78-bucket"  # Cloud Composer bucket

# -----------------------------------------------
# PySpark Job 1: Ingest retailer data from MySQL → GCS
# -----------------------------------------------
GCS_JOB_FILE_1 = f"gs://{COMPOSER_BUCKET}/data/INGESTION/retailerMysqlToLanding.py"
PYSPARK_JOB_1 = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": CLUSTER_NAME},
    "pyspark_job": {"main_python_file_uri": GCS_JOB_FILE_1},
}

# -----------------------------------------------
# PySpark Job 2: Ingest supplier data from MySQL → GCS
# -----------------------------------------------
GCS_JOB_FILE_2 = f"gs://{COMPOSER_BUCKET}/data/INGESTION/supplierMysqlToLanding.py"
PYSPARK_JOB_2 = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": CLUSTER_NAME},
    "pyspark_job": {"main_python_file_uri": GCS_JOB_FILE_2},
}

# -----------------------------------------------
# PySpark Job 3: Ingest customer reviews from external API → GCS
# -----------------------------------------------
GCS_JOB_FILE_3 = f"gs://{COMPOSER_BUCKET}/data/INGESTION/customerReviews_API.py"
PYSPARK_JOB_3 = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": CLUSTER_NAME},
    "pyspark_job": {"main_python_file_uri": GCS_JOB_FILE_3},
}

# -----------------------------------------------
# Default arguments for the DAG
# -----------------------------------------------
ARGS = {
    "owner": "SWAPNIL GAIKWAD",
    "start_date": None,                        # Manual or triggered run only
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
    dag_id="pyspark_dag",
    schedule_interval=None,                  # DAG will only run when triggered
    description="DAG to start a Dataproc cluster, run PySpark jobs, and stop the cluster",
    default_args=ARGS,
    tags=["pyspark", "dataproc", "etl", "marvel"]
) as dag:

    # -----------------------------------------------
    # Task 1: Start the Dataproc cluster
    # -----------------------------------------------
    start_cluster = DataprocStartClusterOperator(
        task_id="start_cluster",
        project_id=PROJECT_ID,
        region=REGION,
        cluster_name=CLUSTER_NAME,
    )

    # -----------------------------------------------
    # Task 2: Submit PySpark job to ingest retailer data
    # -----------------------------------------------
    pyspark_task_1 = DataprocSubmitJobOperator(
        task_id="pyspark_task_1", 
        job=PYSPARK_JOB_1, 
        region=REGION, 
        project_id=PROJECT_ID
    )

    # -----------------------------------------------
    # Task 3: Submit PySpark job to ingest supplier data
    # -----------------------------------------------
    pyspark_task_2 = DataprocSubmitJobOperator(
        task_id="pyspark_task_2", 
        job=PYSPARK_JOB_2, 
        region=REGION, 
        project_id=PROJECT_ID
    )

    # -----------------------------------------------
    # Task 4: Submit PySpark job to ingest customer reviews API data
    # -----------------------------------------------
    pyspark_task_3 = DataprocSubmitJobOperator(
        task_id="pyspark_task_3", 
        job=PYSPARK_JOB_3, 
        region=REGION, 
        project_id=PROJECT_ID
    )

    # -----------------------------------------------
    # Task 5: Stop the Dataproc cluster
    # -----------------------------------------------
    stop_cluster = DataprocStopClusterOperator(
        task_id="stop_cluster",
        project_id=PROJECT_ID,
        region=REGION,
        cluster_name=CLUSTER_NAME,
    )

    # -----------------------------------------------
    # Define the execution order of tasks
    # -----------------------------------------------
    start_cluster >> pyspark_task_1 >> pyspark_task_2 >> pyspark_task_3 >> stop_cluster