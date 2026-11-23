/*
*  ******************************************************  
*  ******  SALES FACT                             *******
*  ******************************************************  
*/

-- ============================================================
-- Simulator scenarios to check the Sales data pipeline
-- ============================================================
-- Execute UPDATE statements to move through scenarios
-- ============================================================

--  *** Scenario 7: initial load for Sales data
-- UPDATE simCurrentLoadScenario SET tls_id = 7;

--  *** Scenario 8: first incremental load for Sales data
-- UPDATE simCurrentLoadScenario SET tls_id = 8;

--  *** Scenario 9: second incremental load for Sales data
-- UPDATE simCurrentLoadScenario SET tls_id = 9;


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
