-- ============================================================
-- Simulator scenarios to check the all-data pipeline
-- ============================================================
-- Execute UPDATE statements to move through scenarios
-- ============================================================

--  *** Scenario 10: do a DWH cleanup 
--  *** before initial loading of all data
-- UPDATE simCurrentLoadScenario SET tls_id = 10;

--  *** Scenario 11: initial load for all data
-- UPDATE simCurrentLoadScenario SET tls_id = 11;

--  *** Scenario 12: first incremental load for all data
-- UPDATE simCurrentLoadScenario SET tls_id = 12;

--  *** Scenario 13: second incremental load for all data
-- UPDATE simCurrentLoadScenario SET tls_id = 13;


/*
*  ******************************************************  
*  ******  STEP 1 : PROCESS PRODUCT DIMENSION     *******
*  ******************************************************  
*/

-- ============================================================
-- Pipeline Task: Process simProduct to rawProduct
--
-- Ingestion into a "bronze" zone for Product data.
-- ============================================================
INSERT INTO rawProduct
(
    prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_start_dt,
    prd_end_dt,
    LOAD_TS_UTC,
    RECORD_SOURCE
)
SELECT 
    pd.prd_id,
    pd.prd_key,
    pd.prd_nm,
    pd.prd_cost,
    pd.prd_start_dt,
    pd.prd_end_dt,
    cls.tls_id AS LOAD_TS_UTC,
    'ERP' AS RECORD_SOURCE
FROM simProduct AS pd
CROSS JOIN simCurrentLoadScenario AS cls;


-- ============================================================
-- Pipeline Task: Process rawProduct to refProduct
--
-- Transform the latest data from "bronze" zone 
-- into refined data in "silver" zone. 
-- ============================================================
WITH tfmProduct AS
(
 SELECT 
    rp.prd_id AS prd_sk,
    TRIM(rp.prd_key) AS prd_code,
    TRIM(rp.prd_nm) AS prd_name,
    rp.prd_cost AS prd_cost,
    rp.prd_start_dt AS prd_start_date,
    COALESCE(rp.prd_end_dt,'9999-01-01') AS prd_end_date,
    rp.LOAD_TS_UTC,
    rp.RECORD_SOURCE
 FROM rawProduct AS rp
 INNER JOIN simCurrentLoadScenario AS cls
   ON cls.tls_id = rp.LOAD_TS_UTC
)
,stgProduct AS
(
 SELECT 
   prd_sk,
   prd_code,
   prd_name,
   prd_cost,
   prd_start_date,
   prd_end_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   concat_ws('|',prd_cost,prd_start_date,prd_end_date) AS HDIFF
FROM tfmProduct
)
INSERT INTO refProduct (
   prd_sk,
   prd_code,
   prd_name,
   prd_cost,
   prd_start_date,
   prd_end_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HDIFF
)
SELECT 
   prd_sk,
   prd_code,
   prd_name,
   prd_cost,
   prd_start_date,
   prd_end_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HDIFF
FROM stgProduct
WHERE true
ON CONFLICT(prd_sk) DO UPDATE 
SET
    prd_code  = excluded.prd_code,
    prd_name  = excluded.prd_name,
    prd_cost  = excluded.prd_cost,
    prd_start_date  = excluded.prd_start_date,
    prd_end_date  = excluded.prd_end_date,
    LOAD_TS_UTC  = excluded.LOAD_TS_UTC,
    RECORD_SOURCE  = excluded.RECORD_SOURCE,
    HDIFF = excluded.HDIFF
WHERE refProduct.HDIFF IS NOT excluded.HDIFF;

/*
*  ******************************************************  
*  ****** STEP 2 : PROCESS CUSTOMER DIMENSION     *******
*  ******************************************************  
*/

-- ============================================================
-- Pipeline Task: Process simCustomer to rawCustomer
--
-- Ingestion into a "bronze" zone for Customer data.
-- ============================================================
INSERT INTO rawCustomer
(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_create_date,
    LOAD_TS_UTC,
    RECORD_SOURCE
)
SELECT 
    sc.cst_id,
    sc.cst_key,
    sc.cst_firstname,
    sc.cst_lastname,
    sc.cst_create_date,
    cls.tls_id AS LOAD_TS_UTC,
    'CRM' AS RECORD_SOURCE
FROM simCustomer AS sc
CROSS JOIN simCurrentLoadScenario AS cls;


-- ============================================================
-- Pipeline Task: Process rawCustomer to refCustomer
--
-- Transform the latest data from "bronze" zone 
-- into refined data in "silver" zone. 
-- ============================================================

WITH tfmCustomer AS
(
 SELECT 
    rc.cst_id AS cst_sk,
    TRIM(rc.cst_key) AS cst_code,
    TRIM( COALESCE(rc.cst_firstname,'') ) AS cst_firstname,
    TRIM( COALESCE(rc.cst_lastname,'') ) AS cst_lastname,
    rc.cst_create_date AS cst_updated_date,
    rc.LOAD_TS_UTC,
    rc.RECORD_SOURCE,
    ROW_NUMBER() OVER (PARTITION BY rc.cst_id ORDER BY rc.cst_create_date DESC ) AS date_idx
 FROM rawCustomer AS rc
 INNER JOIN simCurrentLoadScenario AS cls
   ON cls.tls_id = rc.LOAD_TS_UTC
)
,stgCustomer AS
(
 SELECT 
   cst_sk,
   cst_code,
   cst_firstname,
   cst_lastname,
   cst_updated_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   concat_ws('|',cst_firstname,cst_lastname,cst_updated_date) AS HDIFF
FROM tfmCustomer
WHERE date_idx = 1
)
INSERT INTO refCustomer (
   cst_sk,
   cst_code,
   cst_firstname,
   cst_lastname,
   cst_updated_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HDIFF
)
SELECT 
   cst_sk,
   cst_code,
   cst_firstname,
   cst_lastname,
   cst_updated_date,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HDIFF
FROM stgCustomer
WHERE true
ON CONFLICT(cst_sk) DO UPDATE 
SET
    cst_code  = excluded.cst_code,
    cst_firstname  = excluded.cst_firstname,
    cst_lastname  = excluded.cst_lastname,
    cst_updated_date  = excluded.cst_updated_date,
    LOAD_TS_UTC  = excluded.LOAD_TS_UTC,
    RECORD_SOURCE  = excluded.RECORD_SOURCE,
    HDIFF = excluded.HDIFF
WHERE refCustomer.HDIFF IS NOT excluded.HDIFF;

/*
*  ******************************************************  
*  ****** STEP 3 : PROCESS SALES FACT            *******
*  ******************************************************  
*/

-- ============================================================
-- Pipeline Task: Process simSales to rawSales
--
-- Ingestion into a "bronze" zone for Sales data.
-- ============================================================
INSERT INTO rawSales
(
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  sls_order_dt,
  sls_ship_dt,
  sls_due_dt,
  sls_sales,
  sls_quantity,
  sls_price,
  LOAD_TS_UTC,
  RECORD_SOURCE
)
SELECT 
  sd.sls_ord_num,
  sd.sls_prd_key,
  sd.sls_cust_id,
  sd.sls_order_dt,
  sd.sls_ship_dt,
  sd.sls_due_dt,
  sd.sls_sales,
  sd.sls_quantity,
  sd.sls_price,
  cls.tls_id AS LOAD_TS_UTC,
  'ERP' AS RECORD_SOURCE
FROM simSales AS sd
CROSS JOIN simCurrentLoadScenario AS cls;


-- ============================================================
-- Pipeline Task: Process rawSales to refSales
--
-- Transform the latest data from "bronze" zone 
-- into refined data in "silver" zone. 
-- ============================================================

WITH tfmSales AS
(
 SELECT 
    TRIM(rs.sls_ord_num) AS sls_order_number,
    TRIM(rs.sls_prd_key) AS sls_prd_code,
    rs.sls_cust_id AS sls_cst_sk,
    substr(rs.sls_order_dt, 1, 4) || '-' ||
      substr(rs.sls_order_dt, 5, 2) || '-' || 
      substr(rs.sls_order_dt, 7, 2) AS sls_order_date,

    substr(rs.sls_ship_dt, 1, 4) || '-' ||
      substr(rs.sls_ship_dt, 5, 2) || '-' || 
      substr(rs.sls_ship_dt, 7, 2) AS sls_ship_date,
      
    substr(rs.sls_due_dt, 1, 4) || '-' ||
      substr(rs.sls_due_dt, 5, 2) || '-' || 
      substr(rs.sls_due_dt, 7, 2) AS sls_due_date,
          
    rs.sls_sales AS sls_prd_sales,
    rs.sls_quantity AS sls_prd_quantity,
    rs.LOAD_TS_UTC,
    rs.RECORD_SOURCE
 FROM rawSales AS rs
 INNER JOIN simCurrentLoadScenario AS cls
   ON cls.tls_id = rs.LOAD_TS_UTC
)
,stgSales AS
(
 SELECT 
   t.sls_order_number,
   p.prd_sk AS sls_prd_sk,
   t.sls_cst_sk,
   t.sls_order_date,
   t.sls_ship_date,
   t.sls_due_date,
   t.sls_prd_sales,
   t.sls_prd_quantity,
   t.LOAD_TS_UTC,
   t.RECORD_SOURCE,
   concat_ws('|',t.sls_order_number,t.sls_cst_sk,p.prd_sk) AS HKEY
FROM tfmSales AS t
INNER JOIN refProduct AS p
  ON p.prd_code = t.sls_prd_code
  AND t.sls_order_date >= p.prd_start_date 
  AND t.sls_order_date < p.prd_end_date 
)
INSERT INTO refSales (
   sls_order_number,
   sls_prd_sk,
   sls_cst_sk,
   sls_order_date,
   sls_ship_date,
   sls_due_date,
   sls_prd_sales,
   sls_prd_quantity,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HKEY
)
SELECT
   sls_order_number,
   sls_prd_sk,
   sls_cst_sk,
   sls_order_date,
   sls_ship_date,
   sls_due_date,
   sls_prd_sales,
   sls_prd_quantity,
   LOAD_TS_UTC,
   RECORD_SOURCE,
   HKEY
FROM stgSales
WHERE true
ON CONFLICT(HKEY) DO NOTHING; 
