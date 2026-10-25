-- *********************************************************
-- ***  Statistical queries for the cust_info table       **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Basic statistics for the main fields of cust_info
SELECT 
  COUNT(*) AS TotalRows,
  COUNT(DISTINCT cst_id) AS UniqueIds,
  COUNT(DISTINCT cst_key) AS UniqueKeys,
  COUNT(DISTINCT cst_id || '_' || cst_key) AS UniqueIdAndKey,
  COUNT(*) - COUNT(cst_id) AS IdNullCount,
  COUNT(*) - COUNT(cst_key) AS KeyNullCount,
  COUNT(*) - COUNT(cst_create_date) AS CreatedDateNullCount
FROM cust_info;

----------------------------------------------------------------------------
-- 2. Statistics excluding rows with NULL surrogate keys, with duplicate counts in cust_info
SELECT 
  COUNT(*) AS TotalRows,
  COUNT(DISTINCT cst_id) AS UniqueIds,
  COUNT(DISTINCT cst_key) AS UniqueKeys,
  COUNT(DISTINCT cst_id || '_' || cst_key) AS UniqueIdAndKey,
  COUNT(*) - COUNT( DISTINCT cst_id) AS IdDuplicatesCount,
  COUNT(*) - COUNT( DISTINCT cst_key) AS KeyDuplicatesCount,
  COUNT(*) - COUNT(DISTINCT cst_id || '_' || cst_key) AS IdAndKeyDuplicatesCount,
  COUNT(*) - COUNT(cst_create_date) AS CreatedDateNullCount
FROM cust_info
WHERE cst_id IS NOT NULL;

----------------------------------------------------------------------------
-- 3. Statistics on duplicates in cust_info
SELECT 
  cst_id,
  COUNT(*) AS dupsCount,
  MIN(cst_create_date) AS minCreationDate,
  MAX(cst_create_date) AS maxCreationDate,
  julianday(MAX(cst_create_date)) - julianday(MIN(cst_create_date)) AS maxDateDiff
FROM cust_info
WHERE cst_id IS NOT NULL
GROUP BY cst_id
HAVING COUNT(*) > 1;


-- *********************************************************
-- ***  Statistical queries for the prd_info table        **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Basic statistics for the main fields of prd_info
SELECT 
  COUNT(*) AS TotalRows, 
  COUNT(DISTINCT prd_id) AS UniqueIds,
  COUNT(DISTINCT prd_key) AS UniqueKeys,
  COUNT(DISTINCT prd_id || '_' || prd_key) AS UniqueIdAndKey,
  COUNT(*) - COUNT(prd_id) AS IdNullCount,
  COUNT(*) - COUNT(prd_key) AS KeyNullCount,
  COUNT(*) - COUNT(prd_start_dt) AS StartDateNullCount
FROM prd_info;

----------------------------------------------------------------------------
-- 2. Group statistics in prd_info
WITH group_stats AS (
    -- calc each group
    SELECT 
        prd_key,
        COUNT(*) AS TotalInGroup,
        MAX(prd_id) AS FinalPrdId
    FROM prd_info
    GROUP BY prd_key
),
final_null_stat AS
(
  -- add HasFinalNulls to check if last prd_end_dt is NULL
  SELECT 
     group_stats.prd_key,
     group_stats.TotalInGroup,
     CASE WHEN prd_info.prd_end_dt IS NULL THEN 1 ELSE 0 END AS HasFinalNulls 
  FROM group_stats
  INNER JOIN prd_info
    ON prd_info.prd_id = group_stats.FinalPrdId
)
SELECT 
    TotalInGroup,
    COUNT(*) AS groupsCount,
    COUNT(*) - SUM(HasFinalNulls) AS TotalNotNullEndDateCount,
    SUM(HasFinalNulls) AS TotalNullEndDateCount
FROM final_null_stat
GROUP BY TotalInGroup;


-- *********************************************************
-- ***  Statistical queries for the sales_details table   **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Basic statistics for the main fields of sales_details

SELECT 
  COUNT(*) AS TotalRows, 
  COUNT(DISTINCT sls_ord_num) AS UniqueIds,
  COUNT(DISTINCT sls_prd_key) AS UniqueProductKeys,
  COUNT(DISTINCT sls_cust_id) AS UniqueCustKeys,
  COUNT(DISTINCT sls_prd_key || '_' || sls_cust_id) AS UniqueProdAndCust,
  COUNT(*) - COUNT(sls_ord_num) AS IdsNullCount,
  COUNT(*) - COUNT(sls_prd_key) AS ProductKeysNullCount,
  COUNT(*) - COUNT(sls_cust_id) AS CustKeysNullCount,
  COUNT(*) - COUNT(sls_order_dt) AS OrderDateNullCount,
  COUNT(*) - COUNT(sls_quantity) AS QuantityNullCount
FROM sales_details;

----------------------------------------------------------------------------
-- 2. Group statistics in sales_details

WITH group_stats AS (
    -- calc each group
  SELECT 
    sls_ord_num,
    COUNT(*) AS groupCount
  FROM sales_details
  GROUP BY sls_ord_num
)
SELECT 
    groupCount AS TotalInGroup,
    COUNT(*) AS GroupsCount
FROM group_stats
GROUP BY groupCount;

----------------------------------------------------------------------------
-- 3. Creates the sales_check table (the Product table must exist beforehand)

CREATE TABLE sales_check
AS
SELECT 
 sls_ord_num
 ,sls_prd_key
 ,sls_cust_id
 , Product.min_dt
 , Product.max_dt
 , Product.recCnt AS recCntProduct
 , COUNT(*) OVER(PARTITION BY sls_ord_num) AS recCntSales
 , ROW_NUMBER() OVER ( PARTITION BY sls_ord_num ORDER BY sls_prd_key ASC) AS idSales
FROM sales_details
INNER JOIN Product 
  ON Product.prd_key = sales_details.sls_prd_key
  AND  Product.id = 1;

----------------------------------------------------------------------------
-- 4. Product date statistics for groups with more than one product

SELECT DISTINCT max_dt
FROM sales_check
WHERE recCntSales > 1;

----------------------------------------------------------------------------
-- 5. Product count statistics for groups with more than one product

SELECT DISTINCT recCntProduct
FROM sales_check
WHERE recCntSales > 1;
