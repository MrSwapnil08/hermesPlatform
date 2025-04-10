# hermesPlatform
Implementing CI/CD in Cloud Composer

This guide presents a method for setting up Continuous Integration and Continuous Deployment (CI/CD) in Google Cloud Composer, utilizing Cloud Build and GitHub.

### Project Structure

#### File Layout
```
.
├── dags
│   ├── bq_dag.py
│   ├── pyspark_dag.py
├── data
│   ├── BQ
│   │   ├── bronzeTable.sql
│   │   ├── silverTable.sql
│   │   ├── goldTable.sql
│   ├── DBs
│   │   ├── retailerdb.sql
│   │   ├── supplierdb.sql
│   ├── INGESTION
│   │   ├── customerReviews_API.py
│   │   ├── retailerMysqlToLanding.py
│   │   ├── supplierMysqlToLanding.py
├── utils
│   ├── add_dags_to_composer.py
│   ├── requirements.txt
├── cloudbuild.yaml
├── README.md
```

#### Directory Details
- `dags/`: Contains Directed Acyclic Graphs (DAGs) for orchestrating workflows.
  - `bq_dag.py`: Handles BigQuery workflows.
  - `pyspark_dag.py`: Manages PySpark workflows.

- `data/`: Includes SQL scripts and ingestion logic.
  - `BQ/`: Scripts for creating BigQuery tables (`bronzeTable.sql`, `silverTable.sql`, `goldTable.sql`).
  - `DBs/`: SQL scripts for database initialization (`retailerdb.sql`, `supplierdb.sql`).
  - `INGESTION/`: Python scripts for data ingestion (`customerReviews_API.py`, `retailerMysqlToLanding.py`, `supplierMysqlToLanding.py`).

- `utils/`: Utility scripts supporting deployment.
  - `add_dags_to_composer.py`: Synchronizes DAGs with Cloud Composer after changes.
  - `requirements.txt`: Lists dependencies for utilities.

- `cloudbuild.yaml`: Configuration file for automating CI/CD workflows.

- `README.md`: Documentation explaining the project structure and workflow.

### Automated CI/CD Workflow Steps

1. Develop and Push Changes
   - Modify or create DAGs or ingestion scripts.
   - Push changes to the development branch on GitHub.

2. Create a Pull Request (PR)
   - Open a PR targeting the main branch.

3. Run Validation Tests
   - Cloud Build triggers validation tests to check DAG syntax and integrity.

4. Approval and Merge
   - After review, approve and merge the PR into the main branch.

5. Sync Changes with Cloud Composer
   - Cloud Build synchronizes updated DAGs and dependencies with the Cloud Composer environment.

6. Verify DAG Execution
   - Ensure new DAGs and updates function as expected within Cloud Composer.
  
  
