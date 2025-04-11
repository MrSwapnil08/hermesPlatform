'''Task 1: 
Importing the modules:
- google.cloud.storage: Used to interact with Google Cloud Storage (GCS)
- google.cloud.bigquery: Used to interact with Google BigQuery
- pandas: Used to handle tabular data 
- pyspark.sql import SparkSession: Creates a Spark session for data processing
- datetime: Used for timestamps and file naming
- json: Used to handle JSON data
'''
from google.cloud import storage, bigquery
import pandas as pd
from pyspark.sql import SparkSession
import datetime
import json

#######################################################################
'''Task 2:
Initialize Spark Session
-Creates a Spark session named "SupplierMySQLToLanding" '''

spark = SparkSession.builder.appName("SupplierMySQLToLanding").getOrCreate()

#######################################################################
'''Task 3:
Google Cloud Storage (GCS) Configuration variables
- GCS_BUCKET: Google Cloud Storage bucket name
- LANDING_PATH: The path where new data will be stored in GCS
- ARCHIVE_PATH: The path where old files will be moved before new data arrives
- CONFIG_FILE_PATH: Path to the configuration file (a CSV file in GCS)
'''
GCS_BUCKET = "datalake-project-buckettt"
LANDING_PATH = f"gs://{GCS_BUCKET}/landing/supplier-db/"
ARCHIVE_PATH = f"gs://{GCS_BUCKET}/landing/supplier-db/archive/"
CONFIG_FILE_PATH = f"gs://{GCS_BUCKET}/configs/supplier_config.csv"

#######################################################################

'''Task 4:
BigQuery Configuration
- BQ_PROJECT: Name of the Google Cloud project.
- BQ_AUDIT_TABLE: Table where the pipeline stores audit logs.
- BQ_LOG_TABLE: Table where pipeline logs are stored.
- BQ_TEMP_PATH: Temporary storage location for BigQuery intermediate files.
'''
BQ_PROJECT = "omega-art-450811-b0"
BQ_AUDIT_TABLE = f"{BQ_PROJECT}.temp_dataset1.audit_log"
BQ_LOG_TABLE = f"{BQ_PROJECT}.temp_dataset1.pipeline_logs"
BQ_TEMP_PATH = f"{GCS_BUCKET}/temp/"  

#######################################################################

'''Task 5:
MySQL Configuration
--> As we are reading the data from cloud mysql db
- url: Connection string for MySQL --> Add cloud sql ip address
- driver: JDBC driver used for Spark-MySQL connection.
- user: MySQL username.
- password: MySQL password
'''
MYSQL_CONFIG = {
    "url": "jdbc:mysql://35.196.231.242:3306/supplier_DB?useSSL=false&allowPublicKeyRetrieval=true",
    "driver": "com.mysql.cj.jdbc.Driver",
    "user": "myuser",
    "password": "mypass"
}

#######################################################################

'''Task 6:
Initialize GCS & BigQuery Clients
- storage.Client(): Creates a client to interact with Google Cloud Storage.
- bigquery.Client(): Creates a client to interact with BigQuery.
''' 
storage_client = storage.Client()
bq_client = bigquery.Client()

#######################################################################
'''Task 7:
Logging Mechanism
'''
log_entries = []  # Stores logs before writing to GCS

# FUNCTION 1:
'''
- Adds a log entry with a timestamp, event type, message and table name
- Appends the log to log_entries list created above
- Prints the log for visibility.
'''
def log_event(event_type, message, table=None):
    # Log an event and store it in the log list
    log_entry = {
        "timestamp": datetime.datetime.now().isoformat(),
        "event_type": event_type,
        "message": message,
        "table": table
    }
    log_entries.append(log_entry)
    print(f"[{log_entry['timestamp']}] {event_type} - {message}")  # Print for visibility
    
# FUNCTION 2:
def save_logs_to_gcs():
    #Save logs to a JSON file and upload to GCS
    log_filename = f"pipeline_log_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}.json"
    log_filepath = f"temp/pipeline_logs/{log_filename}"  
    
    json_data = json.dumps(log_entries, indent=4)

    # Get GCS bucket
    bucket = storage_client.bucket(GCS_BUCKET)
    blob = bucket.blob(log_filepath)
    
    # Upload JSON data as a file to GCS in the temp/pipeline_logs/ directory.
    blob.upload_from_string(json_data, content_type="application/json")

    print(f"✅ Logs successfully saved to GCS at gs://{GCS_BUCKET}/{log_filepath}")
    
''' FUNCTION 3:
- Converts log_entries into a Spark DataFrame.
- Write the DataFrame to the BigQuery logs table.
'''
def save_logs_to_bigquery():
    #Save logs to BigQuery
    if log_entries:
        log_df = spark.createDataFrame(log_entries)
        log_df.write.format("bigquery") \
            .option("table", BQ_LOG_TABLE) \
            .option("temporaryGcsBucket", BQ_TEMP_PATH) \
            .mode("append") \
            .save()
        print("✅ Logs stored in BigQuery for future analysis")

#######################################################################
'''Task 8:
Function to Read Config File from GCS
- Read the configuration file from GCS.
- Returns it as a Spark DataFrame.
'''
def read_config_file():
    df = spark.read.csv(CONFIG_FILE_PATH, header=True)
    log_event("INFO", "✅ Successfully read the config file")
    return df
#######################################################################
'''Task 9:
Function to Move Existing Files to Archive
'''

def move_existing_files_to_archive(table):
    # Lists all files in landing/supplier-db/{table}/.
    blobs = list(storage_client.bucket(GCS_BUCKET).list_blobs(prefix=f"landing/supplier-db/{table}/"))
    # Filters files that end with .json.
    existing_files = [blob.name for blob in blobs if blob.name.endswith(".json")]
    
    if not existing_files:
        log_event("INFO", f"No existing files for table {table}")
        return
    
    #Loops over the existing files.
    for file in existing_files:
        source_blob = storage_client.bucket(GCS_BUCKET).blob(file)
        
        # Extract Date from File Name (products_27032025.json)
        date_part = file.split("_")[-1].split(".")[0]
        year, month, day = date_part[-4:], date_part[2:4], date_part[:2]
        
        # Move to Archive
        archive_path = f"landing/supplier-db/archive/{table}/{year}/{month}/{day}/{file.split('/')[-1]}"
        destination_blob = storage_client.bucket(GCS_BUCKET).blob(archive_path)
        
        # Copy file to archive and delete original
        storage_client.bucket(GCS_BUCKET).copy_blob(source_blob, storage_client.bucket(GCS_BUCKET), destination_blob.name)
        source_blob.delete()
        
        log_event("INFO", f"✅ Moved {file} to {archive_path}", table=table)    
        
#######################################################################
'''Task 10:
Function to Get Latest Watermark from BigQuery Audit Table
- Queries BigQuery for the most recent load_timestamp.
- Returns the latest timestamp or a default value.
'''
def get_latest_watermark(table_name):
    query = f"""
        SELECT MAX(load_timestamp) AS latest_timestamp
        FROM `{BQ_AUDIT_TABLE}`
        WHERE tablename = '{table_name}'
    """
    query_job = bq_client.query(query)
    result = query_job.result()
    for row in result:
        return row.latest_timestamp if row.latest_timestamp else "1900-01-01 00:00:00"
    return "1900-01-01 00:00:00"
        
#######################################################################
# TASK 11:
# Function to Extract Data from MySQL and Save to GCS
# Determines whether to extract full or incremental data.
def extract_and_save_to_landing(table, load_type, watermark_col):
    try:
        # Get Latest Watermark
        last_watermark = get_latest_watermark(table) if load_type.lower() == "incremental" else None
        log_event("INFO", f"Latest watermark for {table}: {last_watermark}", table=table)
        
        # Generate SQL Query
        query = f"(SELECT * FROM {table}) AS t" if load_type.lower() == "full load" else \
                f"(SELECT * FROM {table} WHERE {watermark_col} > '{last_watermark}') AS t"
        
        # Read Data from MySQL
        df = (spark.read
                .format("jdbc")
                .option("url", MYSQL_CONFIG["url"])
                .option("user", MYSQL_CONFIG["user"])
                .option("password", MYSQL_CONFIG["password"])
                .option("driver", MYSQL_CONFIG["driver"])
                .option("dbtable", query)
                .load())
        log_event("SUCCESS", f"✅ Successfully extracted data from {table}", table=table)
        
        # Convert Spark DataFrame to JSON
        pandas_df = df.toPandas()
        json_data = pandas_df.to_json(orient="records", lines=True)
        
        # Generate File Path in GCS
        today = datetime.datetime.today().strftime('%d%m%Y')
        JSON_FILE_PATH = f"landing/supplier-db/{table}/{table}_{today}.json"
        
        # Upload JSON to GCS
        bucket = storage_client.bucket(GCS_BUCKET)
        blob = bucket.blob(JSON_FILE_PATH)
        blob.upload_from_string(json_data, content_type="application/json")

        log_event("SUCCESS", f"✅ JSON file successfully written to gs://{GCS_BUCKET}/{JSON_FILE_PATH}", table=table)
        
        # Insert Audit Entry
        audit_df = spark.createDataFrame([
            (table, load_type, df.count(), datetime.datetime.now(), "SUCCESS")], ["tablename", "load_type", "record_count", "load_timestamp", "status"])

        (audit_df.write.format("bigquery")
            .option("table", BQ_AUDIT_TABLE)
            .option("temporaryGcsBucket", GCS_BUCKET)
            .mode("append")
            .save())

        log_event("SUCCESS", f"✅ Audit log updated for {table}", table=table)
    
    except Exception as e:
        log_event("ERROR", f"Error processing {table}: {str(e)}", table=table)
        
#######################################################################
# Main Execution
config_df = read_config_file()

for row in config_df.collect():
    if row["is_active"] == '1':
        db, src, table, load_type, watermark, _, targetpath = row
        move_existing_files_to_archive(table)
        extract_and_save_to_landing(table, load_type, watermark)

save_logs_to_gcs()
save_logs_to_bigquery()       
        
print("✅ Pipeline completed successfully!")