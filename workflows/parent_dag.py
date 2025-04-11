import airflow
from airflow import DAG
from datetime import timedelta
from airflow.utils.dates import days_ago
from airflow.operators.dagrun_operator import TriggerDagRunOperator

# Define default arguments
ARGS = {
    "owner": "SWAPNIL GAIKWAD",
    "start_date": days_ago(1),              # The DAG can be triggered from 1 day ago
    "depends_on_past": False,               # Each task run is independent of previous runs
    "email_on_failure": False,              # No email on task failure
    "email_on_retry": False,                # No email on task retry
    "email": ["***@gmail.com"],             # Email recipient (optional for notification)
    "email_on_success": False,              # No email on success
    "retries": 1,                           # Number of retries if a task fails
    "retry_delay": timedelta(minutes=5)     # Delay between retries
}

# Define the parent DAG
with DAG(
    dag_id="parent_dag",
    schedule_interval="0 5 * * *",     # DAG runs daily at 5:00 AM
    description="Parent DAG to trigger PySpark and BigQuery DAGs",
    default_args=ARGS,
    tags=["parent", "orchestration", "etl"]
) as dag:

    # Task to trigger PySpark DAG
    trigger_pyspark_dag = TriggerDagRunOperator(
        task_id="trigger_pyspark_dag",
        trigger_dag_id="pyspark_dag",  # Name of the child DAG to trigger
        wait_for_completion=True,          # Wait for child DAG to finish before continuing
    )

    # Task to trigger BigQuery DAG
    trigger_bigquery_dag = TriggerDagRunOperator(
        task_id="trigger_bigquery_dag",
        trigger_dag_id="bigquery_dag",   # Name of the second child DAG
        wait_for_completion=True,           # Wait for child DAG to finish before continuing
    )

# Define dependencies
trigger_pyspark_dag >> trigger_bigquery_dag