-- -----------------------------------------------------------------------------
-- CUSTOMERS TABLE (SCD TYPE 2) → Incremental Load
-- -----------------------------------------------------------------------------
--Step 1: Create the customers Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.customers`
(
   customer_id INT64,                     
    name STRING,                         
    email STRING,                      
    updated_at STRING,                     
    is_quarantined BOOL,                   -- Flag to mark bad/incomplete data
    effective_start_date TIMESTAMP,        -- When the current version became valid
    effective_end_date TIMESTAMP,          -- When the current version expired
    is_active BOOL                         -- Whether this version is the latest
);
-- effective_start_date / effective_end_date: Track how long this version was valid.
-- is_active: Tells us which row is the current version.
-- is_quarantined: Marks invalid records (like null name/email).

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Step 2: Deactivate records in Silver where any value has changed
MERGE INTO  `omega-art-450811-b0.silver_dataset1.customers` target
USING 
  (SELECT DISTINCT
    *, 
    CASE 
      WHEN customer_id IS NULL OR email IS NULL OR name IS NULL THEN TRUE
      ELSE FALSE
    END AS is_quarantined,                  -- Flag bad records
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    True as is_active
  FROM `omega-art-450811-b0.bronze_dataset1.customers`) source
ON target.customer_id = source.customer_id AND target.is_active = true
-- Only update if any field has changed
WHEN MATCHED AND 
            (
             target.name != source.name OR
             target.email != source.email OR
             target.updated_at != source.updated_at) 
    THEN UPDATE SET 
        target.is_active = false,                          -- Deactivate current record
        target.effective_end_date = current_timestamp();   -- Close validity period
-- We check for active records in Silver where data has changed.
-- We deactivate them by setting is_active = false and stamping the end time.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 3: Insert New or Updated Records
MERGE INTO  `omega-art-450811-b0.silver_dataset1.customers` target
USING 
  (SELECT DISTINCT
    *, 
    CASE 
      WHEN customer_id IS NULL OR email IS NULL OR name IS NULL THEN TRUE
      ELSE FALSE
    END AS is_quarantined,
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    True as is_active
  FROM `omega-art-450811-b0.bronze_dataset1.customers`) source
ON target.customer_id = source.customer_id AND target.is_active = true
WHEN NOT MATCHED THEN 
    INSERT (customer_id, name, email, updated_at, is_quarantined, effective_start_date, effective_end_date, is_active)
    VALUES (source.customer_id, source.name, source.email, source.updated_at, source.is_quarantined, source.effective_start_date, source.effective_end_date, source.is_active);

-- After deactivating the old row, we insert the new row.
-- This keeps our historical data while marking the current record active.

-- ####################################################################
-- ----------------------------------------------------------------------
-- ORDERS TABLE (SCD TYPE 2) → Incremental Load
-- ----------------------------------------------------------------------

--Step 1: Create the orders Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.orders`
(
    order_id INT64,
    customer_id INT64,
    order_date STRING,
    total_amount FLOAT64,
    updated_at STRING,
    effective_start_date TIMESTAMP,
    effective_end_date TIMESTAMP,
    is_active BOOL
);
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 2: Update Existing Active Records if There Are Changes
MERGE INTO `omega-art-450811-b0.silver_dataset1.orders` target
USING 
  (SELECT DISTINCT
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.orders`) source
ON target.order_id = source.order_id AND target.is_active = true
WHEN MATCHED AND 
            (
             target.customer_id != source.customer_id OR
             target.order_date != source.order_date OR
             target.total_amount != source.total_amount OR
             target.updated_at != source.updated_at
            ) 
    THEN UPDATE SET 
        target.is_active = false,
        target.effective_end_date = current_timestamp();
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 3: Insert New or Updated Records
MERGE INTO `omega-art-450811-b0.silver_dataset1.orders` target
USING 
  (SELECT DISTINCT
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.orders`) source
ON target.order_id = source.order_id AND target.is_active = true
WHEN NOT MATCHED THEN 
    INSERT (order_id, customer_id, order_date, total_amount, updated_at, effective_start_date, effective_end_date, is_active)
    VALUES (source.order_id, source.customer_id, source.order_date, source.total_amount, source.updated_at, source.effective_start_date, source.effective_end_date, source.is_active);
-- ####################################################################
-- -----------------------------------------------------------------------------
-- ORDER_ITEMS TABLE (SCD TYPE 2) → Incremental Load
-- -----------------------------------------------------------------------------
--Step 1: Create the order_items Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.order_items`
(
    order_item_id INT64,
    order_id INT64,
    product_id INT64,
    quantity INT64,
    price FLOAT64,
    updated_at STRING,
    effective_start_date TIMESTAMP,
    effective_end_date TIMESTAMP,
    is_active BOOL
);
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 2: Update Existing Active Records if There Are Changes
MERGE INTO `omega-art-450811-b0.silver_dataset1.order_items` target
USING 
  (SELECT DISTINCT
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.order_items`) source
ON target.order_item_id = source.order_item_id AND target.is_active = true
WHEN MATCHED AND 
            (
             target.order_id != source.order_id OR
             target.product_id != source.product_id OR
             target.quantity != source.quantity OR
             target.price != source.price OR
             target.updated_at != source.updated_at
            ) 
    THEN UPDATE SET 
        target.is_active = false,
        target.effective_end_date = current_timestamp();
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 3: Insert New or Updated Records
MERGE INTO `omega-art-450811-b0.silver_dataset1.order_items` target
USING 
  (SELECT DISTINCT
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.order_items`) source
ON target.order_item_id = source.order_item_id AND target.is_active = true
WHEN NOT MATCHED THEN 
    INSERT (order_item_id, order_id, product_id, quantity, price, updated_at, effective_start_date, effective_end_date, is_active)
    VALUES (source.order_item_id, source.order_id, source.product_id, source.quantity, source.price, source.updated_at, source.effective_start_date, source.effective_end_date, source.is_active);

-- ####################################################################
-- -----------------------------------------------------------------------------
-- CATEGORIES TABLE → Full Load [No SCD here]
-- -----------------------------------------------------------------------------
--Step 1: Create the categories Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.categories`
(
    category_id INT64,
    name STRING,
    updated_at STRING,
    is_quarantined BOOL
);

--Step 2: Truncate table
TRUNCATE TABLE `omega-art-450811-b0.silver_dataset1.categories`;

--Step 3: Insert New or Updated Records
INSERT INTO `omega-art-450811-b0.silver_dataset1.categories`
SELECT 
  *,
  CASE 
    WHEN category_id IS NULL OR name IS NULL THEN TRUE
    ELSE FALSE
  END AS is_quarantined
  
FROM `omega-art-450811-b0.bronze_dataset1.categories`;

-- This is a full refresh pattern:
-- Wipes the table clean and reloads it
-- Good when there's no history requirement and data is small or replaced often

-- ####################################################################
-- -----------------------------------------------------------------------------
-- PRODUCTS TABLE (No SCD here) → Full Load
-- -----------------------------------------------------------------------------
--Step 1: Create the products Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.products`
(
  product_id INT64,
  name STRING,
  category_id INT64,
  price FLOAT64,
  updated_at STRING,
  is_quarantined BOOL
);

--Step 2: Truncate table
TRUNCATE TABLE `omega-art-450811-b0.silver_dataset1.products`;

--Step 3: Insert New or Updated Records
INSERT INTO `omega-art-450811-b0.silver_dataset1.products`
SELECT 
  *,
  CASE 
    WHEN category_id IS NULL OR name IS NULL THEN TRUE
    ELSE FALSE
  END AS is_quarantined
  
FROM `omega-art-450811-b0.bronze_dataset1.products`;

-- ####################################################################
-- -----------------------------------------------------------------------------
-- PRODUCT_SUPPLIER TABLE (SCD TYPE 2) → Incremental Load
-- -----------------------------------------------------------------------------

--Step 1: Create the product_supplier Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.product_suppliers`
(
    supplier_id INT64,
    product_id INT64,
    supply_price FLOAT64,
    last_updated STRING,
    effective_start_date TIMESTAMP,
    effective_end_date TIMESTAMP,
    is_active BOOL
);
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 2: Update Existing Active Records if There Are Changes
MERGE INTO `omega-art-450811-b0.silver_dataset1.product_suppliers` target
USING 
  (SELECT 
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.product_suppliers`) source
ON target.supplier_id = source.supplier_id 
   AND target.product_id = source.product_id 
   AND target.is_active = true
WHEN MATCHED AND 
            (
             target.supply_price != source.supply_price OR
             target.last_updated != source.last_updated
            ) 
    THEN UPDATE SET 
        target.is_active = false,
        target.effective_end_date = current_timestamp();
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 3: Insert New or Updated Records
MERGE INTO `omega-art-450811-b0.silver_dataset1.product_suppliers` target
USING 
  (SELECT 
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.product_suppliers`) source
ON target.supplier_id = source.supplier_id 
   AND target.product_id = source.product_id 
   AND target.is_active = true
WHEN NOT MATCHED THEN 
    INSERT (supplier_id, product_id, supply_price, last_updated, effective_start_date, effective_end_date, is_active)
    VALUES (source.supplier_id, source.product_id, source.supply_price, source.last_updated, source.effective_start_date, source.effective_end_date, source.is_active);

-- ####################################################################
-- -----------------------------------------------------------------------------
-- SUPPLIERS TABLE (No SCD here) → Full Load
-- -----------------------------------------------------------------------------
--Step 1: Create the suppliers Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.suppliers`
(
  supplier_id INT64,
  supplier_name STRING,
  contact_name STRING,
  phone STRING,
  email STRING,
  address STRING,
  city STRING,
  country STRING,
  created_at STRING,
  is_quarantined BOOL
);

--Step 2: Truncate table
TRUNCATE TABLE `omega-art-450811-b0.silver_dataset1.suppliers`;

--Step 3: Insert New or Updated Records
INSERT INTO `omega-art-450811-b0.silver_dataset1.suppliers`
SELECT 
  *,
  CASE 
    WHEN supplier_id IS NULL OR supplier_name IS NULL THEN TRUE
    ELSE FALSE
  END AS is_quarantined
  
FROM `omega-art-450811-b0.bronze_dataset1.suppliers`;

-- ####################################################################
-- -----------------------------------------------------------------------------
-- CUSTOMER_REVIEWS TABLE (SCD TYPE 2) → Incremental Load
-- -----------------------------------------------------------------------------
--Step 1: Create the customer_reviews Table in the Silver Layer
CREATE TABLE IF NOT EXISTS `omega-art-450811-b0.silver_dataset1.customer_reviews`
(
    id STRING,
    customer_id INT64,
    product_id INT64,
    rating INT64,
    review_text STRING,
    review_date STRING,
    effective_start_date TIMESTAMP,
    effective_end_date TIMESTAMP,
    is_active BOOL
);
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 2: Update Existing Active Records if There Are Changes
MERGE INTO `omega-art-450811-b0.silver_dataset1.customer_reviews` target
USING 
  (SELECT 
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.customer_reviews`) source
ON target.id = source.id AND target.is_active = true
WHEN MATCHED AND 
            (
             target.customer_id != source.customer_id OR
             target.product_id != source.product_id OR
             target.rating != source.rating OR
             target.review_text != source.review_text OR
             target.review_date != source.review_date
            ) 
    THEN UPDATE SET 
        target.is_active = false,
        target.effective_end_date = current_timestamp();
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--Step 3: Insert New or Updated Records
MERGE INTO `omega-art-450811-b0.silver_dataset1.customer_reviews` target
USING 
  (SELECT 
    *, 
    CURRENT_TIMESTAMP() AS effective_start_date,
    CURRENT_TIMESTAMP() AS effective_end_date,
    TRUE AS is_active
  FROM `omega-art-450811-b0.bronze_dataset1.customer_reviews`) source
ON target.id = source.id AND target.is_active = true
WHEN NOT MATCHED THEN 
    INSERT (id, customer_id, product_id, rating, review_text, review_date, effective_start_date, effective_end_date, is_active)
    VALUES (source.id, source.customer_id, source.product_id, source.rating, source.review_text, source.review_date, source.effective_start_date, source.effective_end_date, source.is_active);