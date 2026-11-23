/*
*  ******************************************************  
*  ******  PRODUCT DIMENSION                      *******
*  ******************************************************  
*/

-- ============================================================
-- Simulator scenarios to check the Product data pipeline
-- ============================================================
-- Execute UPDATE statements to move through scenarios
-- ============================================================

--  *** Scenario 4: initial load for Product data
-- UPDATE simCurrentLoadScenario SET tls_id = 4;

--  *** Scenario 5: first incremental load for Product data
-- UPDATE simCurrentLoadScenario SET tls_id = 5;

--  *** Scenario 6: second incremental load for Product data
-- UPDATE simCurrentLoadScenario SET tls_id = 6;


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
