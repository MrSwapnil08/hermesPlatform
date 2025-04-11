-- 🔹 Create external table for ORDERS in bronze layer
-- Reads JSON data directly from GCS landing zone (no data stored in BigQuery yet)
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.orders`(
    order_id INT64,
    customer_id INT64,
    order_date STRING,
    total_amount FLOAT64,
    updated_at STRING   -- Used for incremental loads or tracking changes
)
OPTIONS (
  format = 'JSON',
  uris = ['gs://datalake-project-buckettt/landing/retailer-db/orders/*.json']  -- GCS path to landing files
);


-- 🔹 External table for CUSTOMERS
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.customers`
(
    customer_id INT64,
    name STRING,
    email STRING,
    updated_at STRING
)
OPTIONS (
    format = 'JSON',
    uris = ['gs://datalake-project-buckettt/landing/retailer-db/customers/*.json']
);


-- 🔹 External table for PRODUCTS
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.products`
(
    product_id INT64,
    name STRING,
    category_id INT64,
    price FLOAT64,
    updated_at STRING
)
OPTIONS (
    format = 'JSON',
    uris = ['gs://datalake-project-buckettt/landing/retailer-db/products/*.json']
);


-- 🔹 External table for CATEGORIES
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.categories`
(
    category_id INT64,
    name STRING,
    updated_at STRING
)
OPTIONS (
    format = 'JSON',
    uris = ['gs://datalake-project-buckettt/landing/retailer-db/categories/*.json']
);


-- 🔹 External table for ORDER ITEMS
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.order_items`
(
    order_item_id INT64,
    order_id INT64,
    product_id INT64,
    quantity INT64,
    price FLOAT64,
    updated_at STRING
)
OPTIONS (
    format = 'JSON',
    uris = ['gs://datalake-project-buckettt/landing/retailer-db/order_items/*.json']
);


-----------------------------------------------------------------------------------------------------------
-- Suppliers Table
-- 🔹 External table for SUPPLIERS
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.suppliers` (
    supplier_id INT64,
    supplier_name STRING,
    contact_name STRING,
    phone STRING,
    email STRING,
    address STRING,
    city STRING,
    country STRING,
    created_at STRING
)
OPTIONS (
  format = 'JSON',
  uris = ['gs://datalake-project-buckettt/landing/supplier-db/suppliers/*.json']
);


-- 🔹 External table for PRODUCT_SUPPLIERS (link between products and their suppliers)
CREATE EXTERNAL TABLE IF NOT EXISTS `omega-art-450811-b0.bronze_dataset1.product_suppliers` (
    supplier_id INT64,
    product_id INT64,
    supply_price FLOAT64,
    last_updated STRING
)
OPTIONS (
  format = 'JSON',
  uris = ['gs://datalake-project-buckettt/landing/supplier-db/product_suppliers/*.json']
);


-----------------------------------------------------------------------------------------------------------
-- 🔹 External table for CUSTOMER REVIEWS
-- This one reads from Parquet files instead of JSON
CREATE OR REPLACE EXTERNAL TABLE `omega-art-450811-b0.bronze_dataset1.customer_reviews` (
  id STRING,
  customer_id INT64,
  product_id INT64,
  rating INT64,
  review_text STRING,
  review_date STRING
)
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://datalake-project-buckettt/landing/customer_reviews/customer_reviews_*.parquet']
);