/*
*  ******************************************************  
*  ******  PRODUCT DIMENSION                      *******
*  ******************************************************  
*/

-- ============================================================
-- DDL: Creating the rawProduct table
-- ============================================================
-- The table represents a "bronze" zone for Product data.
-- ============================================================

DROP TABLE IF EXISTS rawProduct;

CREATE TABLE rawProduct (
    prd_id           INTEGER,
    prd_key          TEXT,
    prd_nm           TEXT,
    prd_cost         INTEGER,
    prd_start_dt     TEXT,
    prd_end_dt       TEXT,
    
-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT      -- source
);

-- ============================================================
-- DDL: Creating the refProduct table
-- ============================================================
-- The table represents refined data 
-- in a "silver" zone for Product data.
-- ============================================================

DROP TABLE IF EXISTS refProduct;

CREATE TABLE refProduct (
    prd_sk           INTEGER,
    prd_code         TEXT,
    prd_name         TEXT,
    prd_cost         INTEGER,
    prd_start_date   TEXT,
    prd_end_date     TEXT,
    
-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT,      -- source
-- ** column difference  **    
    HDIFF            TEXT
);

-- create the unique index for the key column
CREATE UNIQUE INDEX UQ_refProduct_prd_sk ON refProduct(prd_sk);

-- ============================================================
-- DDL: Creating the dimProduct view
-- ============================================================
-- The view displays business data
-- in a "gold" zone for Product data.
-- ============================================================

DROP VIEW IF EXISTS dimProduct;

CREATE VIEW dimProduct
AS
SELECT
    prd_sk AS Product_Key
   ,prd_code AS "Product Code"
   ,prd_name AS "Product Name"
   ,prd_cost AS "Product Cost"
   ,prd_start_date AS "Product Effective Start Date"
   ,prd_end_date AS "Product Effective End Date"
   ,CASE
       WHEN prd_start_date <= CURRENT_DATE AND prd_end_date > CURRENT_DATE
           THEN 'Yes'
           ELSE 'No'
    END AS "Is Current Product"
FROM refProduct;

/*
*  ******************************************************  
*  ******  CUSTOMER DIMENSION                     *******
*  ******************************************************  
*/

-- ============================================================
-- DDL: Creating the rawCustomer table
-- ============================================================
-- The table represents a "bronze" zone for Customer data.
-- ============================================================

DROP TABLE IF EXISTS rawCustomer;

CREATE TABLE rawCustomer (
    cst_id           INTEGER,
    cst_key          TEXT,
    cst_firstname    TEXT,
    cst_lastname     TEXT,
    cst_create_date  TEXT,

-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT      -- source
);

-- ============================================================
-- DDL: Creating the refCustomer table
-- ============================================================
-- The table represents refined data 
-- in a "silver" zone for Customer data.
-- ============================================================

DROP TABLE IF EXISTS refCustomer;

CREATE TABLE refCustomer (
    cst_sk           INTEGER,
    cst_code         TEXT,
    cst_firstname    TEXT,
    cst_lastname     TEXT,
    cst_updated_date TEXT,
    
-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT,      -- source
-- ** column difference  **    
    HDIFF            TEXT
);

-- create the unique index for the key column
CREATE UNIQUE INDEX UQ_refCustomer_cst_sk ON refCustomer(cst_sk);

-- ============================================================
-- DDL: Creating the dimCustomer view
-- ============================================================
-- The view displays business data
-- in a "gold" zone for Customer data.
-- ============================================================

DROP VIEW IF EXISTS dimCustomer;

CREATE VIEW dimCustomer
AS
SELECT
   cst_sk AS Customer_Key
  ,cst_code AS "Customer Code"
  ,cst_firstname AS "Customer First Name"
  ,cst_lastname AS "Customer Last Name"
  ,cst_updated_date AS "Customer Last Modified Date"
FROM refCustomer;

/*
*  ******************************************************  
*  ******  SALES FACT                             *******
*  ******************************************************  
*/

-- ============================================================
-- DDL: Creating the rawSales table
-- ============================================================
-- The table represents a "bronze" zone for Sales data.
-- ============================================================

DROP TABLE IF EXISTS rawSales;

CREATE TABLE rawSales (
    sls_ord_num      TEXT,
    sls_prd_key      TEXT,
    sls_cust_id      INTEGER,
    sls_order_dt     TEXT,
    sls_ship_dt      TEXT,
    sls_due_dt       TEXT,
    sls_sales        INTEGER,
    sls_quantity     INTEGER,
    sls_price        INTEGER,
    
-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT      -- source
);


-- ============================================================
-- DDL: Creating the refSales table
-- ============================================================
-- The table represents refined data 
-- in a "silver" zone for Sales data.
-- ============================================================

DROP TABLE IF EXISTS refSales;

CREATE TABLE refSales (
    sls_order_number TEXT,
    sls_prd_sk       INTEGER,
    sls_cst_sk       INTEGER,
    sls_order_date   TEXT,
    sls_ship_date    TEXT,
    sls_due_date     TEXT,
    sls_prd_sales    INTEGER,
    sls_prd_quantity INTEGER,
    
-- ** storing the history  **
    LOAD_TS_UTC      INTEGER,  -- load timestamp (UTC)
    RECORD_SOURCE    TEXT,      -- source
-- ** unique key  **    
    HKEY             TEXT
);

-- create the unique index for the key column
CREATE UNIQUE INDEX UQ_refSales_HKEY ON refSales(HKEY);

-- ============================================================
-- DDL: Creating the factSales view
-- ============================================================
-- The view displays business data
-- in a "gold" zone for Sales data.
-- ============================================================

DROP VIEW IF EXISTS factSales;

CREATE VIEW factSales
AS
SELECT
   sls_order_number AS "Sales Order Number"
  ,sls_prd_sk AS Product_Key
  ,sls_cst_sk AS Customer_Key
  ,sls_order_date AS "Sales Order Date"
  ,sls_ship_date AS "Shipment Date"
  ,sls_due_date AS "Delivery Due Date"
  ,sls_prd_sales AS "Product Sales (per Order)"
  ,sls_prd_quantity AS "Item Quantity"
FROM refSales;

-- ============================================================
-- DDL: Creating the "clear_raw_ref_when_tls_id_is_10" trigger
-- ============================================================
-- The trigger performs clearing of all tables
-- when dedicated scenario 10 is selected
-- USAGE: UPDATE simCurrentLoadScenario SET tls_id = 10;
-- ============================================================

DROP TRIGGER IF EXISTS clear_raw_ref_when_tls_id_is_10;

CREATE TRIGGER clear_raw_ref_when_tls_id_is_10
AFTER UPDATE OF tls_id ON simCurrentLoadScenario
WHEN NEW.tls_id = 10 AND OLD.tls_id <> 10
BEGIN
  DELETE FROM rawProduct;
  DELETE FROM rawCustomer;
  DELETE FROM rawSales;
  DELETE FROM refProduct;
  DELETE FROM refCustomer;
  DELETE FROM refSales;
END;

