/*
*  ******************************************************  
*  ******  CUSTOMER DIMENSION                     *******
*  ******************************************************  
*/

-- ============================================================
-- Simulator scenarios to check the Customer data pipeline
-- ============================================================
-- Execute UPDATE statements to move through scenarios
-- ============================================================

--  *** Scenario 1: initial load for Customer data
-- UPDATE simCurrentLoadScenario SET tls_id = 1;

--  *** Scenario 2: first incremental load for Customer data
-- UPDATE simCurrentLoadScenario SET tls_id = 2;

--  *** Scenario 3: second incremental load for Customer data
-- UPDATE simCurrentLoadScenario SET tls_id = 3;


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

