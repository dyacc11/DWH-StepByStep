-- *********************************************************
-- *** Generation queries for the Customer table          **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Creating the Customer table

CREATE TABLE Customer AS
WITH
bounds AS (
    SELECT '2025-01-01' AS A, 365 AS B
)
SELECT
  cst_id,
  cst_key,
  cst_firstname,
  cst_lastname,
  cst_create_date,
  COUNT(*) OVER(PARTITION BY cst_id) AS dupCnt,
  ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date ASC) AS dupNo,
  date(bounds.A, '+' || (ABS(RANDOM()) % bounds.B) || ' days' ) AS newDate   
FROM cust_info, bounds
WHERE cst_id IS NOT NULL;

----------------------------------------------------------------------------
-- 2. Updating dates for duplicates

UPDATE Customer
SET 
   newDate = date(prev.newDate, '+1 days' ) 
FROM Customer AS prev
WHERE Customer.cst_id = prev.cst_id
AND Customer.dupNo = 2
AND prev.dupNo = 1
AND prev.dupCnt > 1;

UPDATE Customer
SET 
   newDate = date(prev.newDate, '+1 days' ) 
FROM Customer AS prev
WHERE Customer.cst_id = prev.cst_id
AND Customer.dupNo = 3
AND prev.dupNo = 2
AND prev.dupCnt > 2;

----------------------------------------------------------------------------
-- 3. Updating the cst_create_date field using the newly generated date

UPDATE Customer
SET cst_create_date = newDate;

----------------------------------------------------------------------------
-- 4. Checking for customers not present in sales facts

SELECT * FROM sales_details
WHERE sls_cust_id NOT IN ( SELECT cst_id FROM Customer );

----------------------------------------------------------------------------
-- 5. Removing auxiliary columns from the table

ALTER TABLE Customer DROP COLUMN dupCnt;
ALTER TABLE Customer DROP COLUMN dupNo;
ALTER TABLE Customer DROP COLUMN newDate;

----------------------------------------------------------------------------
--- ! Now the Customer table can be exported

-- *********************************************************
-- *** Generation queries for the Product table           **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Creating the Product table

CREATE TABLE Product AS
SELECT 
  prd_id 
  , SUBSTR(prd_key, 7) AS prd_key
  , prd_nm
  , prd_cost
  , prd_start_dt
  , prd_end_dt
  , COUNT(*) OVER(PARTITION BY prd_key) AS recCnt
  , ROW_NUMBER() OVER ( PARTITION BY prd_key ORDER BY prd_id ASC) AS id
  , CAST(NULL AS TEXT) AS date1
  , CAST(NULL AS TEXT) AS date2
  , CAST(NULL AS TEXT) AS date3
  , CAST(NULL AS TEXT) AS min_dt
  , CAST(NULL AS TEXT) AS max_dt    
FROM prd_info;

----------------------------------------------------------------------------
-- 2. Removing products from the Product table that have no sales facts

DELETE FROM Product
WHERE prd_key NOT IN (SELECT sls_prd_key FROM sales_details);

----------------------------------------------------------------------------
-- 3. Generating three random dates for SCD 2 for products

WITH RECURSIVE
  -- 1. get unique business keys
target_list AS (
   SELECT DISTINCT prd_key
   FROM Product
),
  -- 2. range for dates generation
bounds AS (
    SELECT '2025-01-01' AS A, 365 AS B
),
  -- 3. recursive generator for each key
generator(prd_key, idx, date_result) AS (
    -- first date
    SELECT 
        t.prd_key, 
        1, 
        date(b.A, '+' || (ABS(RANDOM() + t.prd_key) % b.B) || ' days') 
    FROM target_list t, bounds b
    UNION ALL
    -- next dates, up to 3 for each key
    SELECT 
        g.prd_key,
        g.idx + 1,
        date(b.A, '+' || (ABS(RANDOM() + g.idx) % b.B) || ' days')
    FROM generator g, bounds b
    WHERE g.idx < 3
),
  -- 4. remove duplicates for each key
unique_dates AS (
    SELECT prd_key, date_result 
    FROM generator 
    GROUP BY prd_key, date_result
),
  -- 5. final output with numbering (1, 2, 3) for each key
num_data AS ( 
 SELECT 
    prd_key,
    ROW_NUMBER() OVER (PARTITION BY prd_key ORDER BY date_result ASC) AS genId,
    date_result
 FROM unique_dates
)
,
final_data AS (
  SELECT prd_key,
    MAX(date_result) FILTER (WHERE genId = 1) AS [date1],
    MAX(date_result) FILTER (WHERE genId = 2) AS [date2],
    MAX(date_result) FILTER (WHERE genId = 3) AS [date3] 
  FROM num_data
  GROUP BY prd_key
)
UPDATE Product
SET 
   date1 = final_data.date1
   , date2 = final_data.date2
   , date3 = final_data.date3
FROM final_data
WHERE Product.prd_key = final_data.prd_key; 

-- check that there are no NULLs in date1, date2, date3
SELECT * FROM Product 
WHERE date1 IS NULL OR date2 IS NULL OR date3 IS NULL;

----------------------------------------------------------------------------
-- 4. Updating validity intervals

UPDATE Product
SET 
  prd_start_dt = date1 
  ,prd_end_dt = CASE WHEN prd_end_dt IS NOT NULL THEN date2 ELSE NULL END
WHERE id  =  1;

UPDATE Product
SET 
  prd_start_dt = date2 
  ,prd_end_dt = CASE WHEN prd_end_dt IS NOT NULL THEN date3 ELSE NULL END
WHERE id  =  2;

UPDATE Product
SET 
  prd_start_dt = date3 
WHERE id  =  3;

----------------------------------------------------------------------------
-- 5. Calculating the maximum and minimum dates for validity intervals

WITH _rngs AS
(
SELECT prd_key,
   MIN ( prd_start_dt ) AS mn,
   MAX ( COALESCE( prd_end_dt, '2025-12-31')) AS mx
FROM Product
GROUP BY prd_key 
)
UPDATE Product
SET 
   min_dt = _rngs.mn
   , max_dt = _rngs.mx
FROM _rngs
WHERE Product.prd_key = _rngs.prd_key; 


-- *********************************************************
-- *** Generation queries for the Sales table             **
-- *********************************************************

----------------------------------------------------------------------------
-- 1. Creating the sales_groups_dates table
--  (the sales_check table was created in the statistical queries)

CREATE TABLE sales_groups_dates
AS
WITH _maxD AS
(
  SELECT 
    sls_ord_num
    , MAX(min_dt) AS startD
  FROM sales_check
  GROUP BY sls_ord_num
)
SELECT 
  _maxD.sls_ord_num
  , sales_check.recCntSales
  , _maxD.startD AS startDate
  , sales_check.max_dt AS endDate
  , CAST(NULL AS TEXT) AS newOrderDate
  , CAST(NULL AS TEXT) AS newShipDate
  , CAST(NULL AS TEXT) AS newDueDate
FROM _maxD
INNER JOIN sales_check
 ON sales_check.sls_ord_num = _maxD.sls_ord_num
 AND sales_check.idSales = 1;

----------------------------------------------------------------------------
-- 2. Checking data for two groups: one with a single product and one with four products

SELECT 
  sc.sls_ord_num
  ,sc.sls_prd_key
  ,sc.min_dt
  ,sc.max_dt 
  ,sd.recCntSales
  ,sd.startDate
  ,sd.endDate
  ,sd.newOrderDate
  ,sd.newShipDate
  ,sd.newDueDate
FROM sales_check AS sc
INNER JOIN sales_groups_dates AS sd
  ON sd.sls_ord_num = sc.sls_ord_num
WHERE sc.sls_ord_num IN ( 'SO54115', 'SO43698');

----------------------------------------------------------------------------
-- 3. Updating order, shipping, and due dates

UPDATE sales_groups_dates
SET newOrderDate = 
  date(
    julianday(startDate) + 
     (abs(random()) % (julianday(endDate) - julianday(startDate) ))
  );

UPDATE sales_groups_dates
SET newShipDate = date(newOrderDate, '+' || (1 + abs(random()) % 4) || ' days');

UPDATE sales_groups_dates
SET newDueDate = date(newShipDate, '+' || (1 + abs(random()) % 4) || ' days');

----------------------------------------------------------------------------
-- 4. Verifying that each product in sales has a matching product within the date range

SELECT *
FROM sales_check
EXCEPT
SELECT sc.*
FROM sales_check as sc
INNER JOIN sales_groups_dates AS gd
  ON gd.sls_ord_num = sc.sls_ord_num
INNER JOIN Product AS pd
  ON sc.sls_prd_key = pd.prd_key
  AND gd.newOrderDate >=  pd.prd_start_dt
  and ( gd.newOrderDate < pd.prd_end_dt OR pd.prd_end_dt IS NULL)
;

----------------------------------------------------------------------------
-- 5. Creating the Sales table

CREATE TABLE Sales
AS
SELECT 
  sc.sls_ord_num,
  sc.sls_prd_key,
  sc.sls_cust_id,
  replace(gd.newOrderDate, '-', '') sls_order_dt,
  replace(gd.newShipDate, '-', '') AS sls_ship_dt,
  replace(gd.newDueDate, '-', '') AS sls_due_dt,
  CAST(pd.prd_cost AS INT) * CAST(sd.sls_quantity AS INT) AS sls_sales,
  CAST(sd.sls_quantity AS INT) AS sls_quantity,
  CAST(pd.prd_cost AS INT) AS sls_price

FROM sales_check as sc
INNER JOIN sales_groups_dates AS gd
  ON gd.sls_ord_num = sc.sls_ord_num
INNER JOIN sales_details AS sd
  ON  sd.sls_prd_key = sc.sls_prd_key
  AND  sd.sls_ord_num = sc.sls_ord_num
  AND  sd.sls_cust_id = sc.sls_cust_id
INNER JOIN Product AS pd
  ON sc.sls_prd_key = pd.prd_key
  AND gd.newOrderDate >=  pd.prd_start_dt
  and ( gd.newOrderDate < pd.prd_end_dt OR pd.prd_end_dt IS NULL)
;

----------------------------------------------------------------------------
-- 6. Checking data for two groups

SELECT *
FROM Sales
WHERE sls_ord_num IN ( 'SO54115', 'SO43698');

SELECT *
FROM sales_details
WHERE sls_ord_num IN ( 'SO54115', 'SO43698');

SELECT 
  prd_id,
  prd_key,
  prd_nm,
  prd_cost,
  prd_start_dt,
  prd_end_dt
FROM Product 
WHERE prd_key IN ('BK-M82S-44','TI-T723','TT-T092','HY-1023-70','CL-9009');

----------------------------------------------------------------------------
-- 7. Removing auxiliary columns from the Product table and dropping auxiliary tables

ALTER TABLE Product DROP COLUMN recCnt;
ALTER TABLE Product DROP COLUMN id;
ALTER TABLE Product DROP COLUMN date1;
ALTER TABLE Product DROP COLUMN date2;
ALTER TABLE Product DROP COLUMN date3;
ALTER TABLE Product DROP COLUMN min_dt;
ALTER TABLE Product DROP COLUMN max_dt;

DROP TABLE sales_check;
DROP TABLE sales_groups_dates;

----------------------------------------------------------------------------
--- ! Now the Product and Sales tables can be exported