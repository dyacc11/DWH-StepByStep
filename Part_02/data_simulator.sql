-- ============================================================
-- DDL: Creating the customerData table
-- ============================================================
-- Table contains test data for the "Customer" dimension
-- with bitmask support for simulating incremental loads.
-- ============================================================

CREATE TABLE customerData (
    cst_id           INTEGER,
    cst_key          TEXT,
    cst_firstname    TEXT,
    cst_lastname     TEXT,
    cst_create_date  TEXT,
    load_id          INTEGER,
    for_mask         INTEGER
);

-- ============================================================
-- DML: Populating the customerData table
-- ============================================================
-- Data covers three load scenarios:
--   load_id = 1  (bitmask 001) - initial load
--   load_id = 2  (bitmask 010) - first incremental load
--   load_id = 4  (bitmask 100) - second incremental load
-- ============================================================

INSERT INTO customerData 
    (cst_id, cst_key, cst_firstname, cst_lastname, cst_create_date, load_id, for_mask) 
VALUES
    -- === Initial load (load_id = 1) ===
    (1001, 'TV00001001', 'Verity',  'Terry',  '2025-01-01', 1, 0),  -- simple single record
    (1002, 'TV00001002', NULL,      NULL,     '2025-01-01', 1, 0),  -- first pair of duplicates by key
    (1002, 'TV00001002', 'Vivian',  'Turner', '2025-01-02', 1, 0),  -- first pair of duplicates by key
    (1003, 'TV00001003', NULL,      'Tucker', '2025-01-04', 1, 1),  -- removed in the second and third loads
    (1003, 'TV00001003', 'V',       'Tucker', '2025-01-05', 1, 0),  -- second pair of duplicates by key

    -- === First incremental load (load_id = 2) ===
    (1003, 'TV00001003', 'Vishal',  'Tucker', '2025-01-13', 2, 0),  -- second load update
    (1004, 'TV00001004', 'V',       'T',      '2025-01-14', 2, 0),  -- new record of the second load

    -- === Second incremental load (load_id = 4) ===
    (1004, 'TV00001004', 'Vivek',   'T',      '2025-02-15', 4, 0),  -- third load update
    (1004, 'TV00001004', 'Vivek',   'Tripp',  '2025-02-16', 4, 0);  -- third load update


-- ============================================================
-- DDL: Creating the productData table
-- ============================================================
-- Table contains test data for the "Product" dimension
-- with SCD Type 2 support (validity intervals).
-- For products, changes are incremental, so bitmasks are not required.
-- ============================================================

CREATE TABLE productData (
    prd_id           INTEGER,
    prd_key          TEXT,
    prd_nm           TEXT,
    prd_cost         INTEGER,
    prd_start_dt     TEXT,
    prd_end_dt       TEXT,
    load_id          INTEGER
);

-- ============================================================
-- DML: Populating the productData table
-- ============================================================
-- Data covers three load scenarios:
--   load_id = 1 - initial load
--   load_id = 2 - first incremental load
--   load_id = 3 - second incremental load
-- ============================================================

INSERT INTO productData 
    (prd_id, prd_key, prd_nm, prd_cost, prd_start_dt, prd_end_dt, load_id) 
VALUES
    -- === Initial load (load_id = 1) ===
    (101, 'TV-SD10-L',  'Track Vest SporticsDog - L',  10, '2025-01-01', '2025-03-01', 1),  -- closed validity interval
    (102, 'TV-MC70-S',  'Track Vest Mike and Cat - S',  5, '2025-01-02', NULL,         1),  -- open validity interval
    (103, 'TV-JJ17-XS', 'Track Vest JJ Run - XS',       7, '2025-01-03', '2025-02-05', 1),  -- first interval of two
    (104, 'TV-JJ17-XS', 'Track Vest JJ Run - XS',       9, '2025-02-05', NULL,         1),  -- second interval of two

    -- === First incremental load (load_id = 2) ===
    (102, 'TV-MC70-S',  'Track Vest Mike and Cat - S',  5, '2025-01-02', '2025-02-05', 2),  -- close previous interval
    (105, 'TV-MC70-S',  'Track Vest Mike and Cat - S',  7, '2025-02-05', NULL,         2),  -- new validity interval
    (106, 'TV-JJ17-XL', 'Track Vest JJ Run - XL',       8, '2025-02-03', NULL,         2),  -- new product

    -- === Second incremental load (load_id = 3) ===
    (104, 'TV-JJ17-XS', 'Track Vest JJ Run - XS',       9, '2025-02-05', '2025-03-03', 3),  -- close previous interval
    (107, 'TV-JJ17-XS', 'Track Vest JJ Run - XS',      11, '2025-03-03', NULL,         3),  -- new validity interval
    (106, 'TV-JJ17-XL', 'Track Vest JJ Run - XL',       8, '2025-02-03', '2025-04-03', 3);  -- close interval for XL


-- ============================================================
-- DDL: Creating the salesData table
-- ============================================================
-- Table contains test data for the "Sales" fact table.
-- This is the simplest table in terms of loading, as data is only
-- appended to it. It is only necessary to take into account the
-- product validity interval when joining with the Product dimension.
-- ============================================================

CREATE TABLE salesData (
    sls_ord_num      TEXT,
    sls_prd_key      TEXT,
    sls_cust_id      INTEGER,
    sls_order_dt     TEXT,
    sls_ship_dt      TEXT,
    sls_due_dt       TEXT,
    sls_sales        INTEGER,
    sls_quantity     INTEGER,
    sls_price        INTEGER,
    load_id          INTEGER
);

-- ============================================================
-- DML: Populating the salesData table
-- ============================================================
-- Data covers three load scenarios:
--   load_id = 1 - initial load
--   load_id = 2 - first incremental load
--   load_id = 3 - second incremental load
-- ============================================================

INSERT INTO salesData 
    (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price, load_id) 
VALUES
    -- === Initial load (load_id = 1) ===
    ('TVSO101', 'TV-SD10-L',  1001, '20250104', '20250106', '20250109', 10, 1, 10, 1),  -- two products from customer 1001
    ('TVSO101', 'TV-JJ17-XS', 1001, '20250104', '20250106', '20250109', 14, 2,  7, 1),
    ('TVSO102', 'TV-SD10-L',  1002, '20250105', '20250109', '20250111', 10, 1, 10, 1),  -- two products from customer 1002
    ('TVSO102', 'TV-MC70-S',  1002, '20250105', '20250109', '20250111',  5, 1,  5, 1),

    -- === First incremental load (load_id = 2) ===
    ('TVSO103', 'TV-JJ17-XL', 1001, '20250206', '20250208', '20250209',  8, 1,  8, 2),  -- products with changed price in February
    ('TVSO103', 'TV-MC70-S',  1001, '20250206', '20250208', '20250209', 14, 2,  7, 2),  -- same customers as in initial load
    ('TVSO104', 'TV-JJ17-XL', 1002, '20250207', '20250209', '20250211',  9, 1,  9, 2),
    ('TVSO104', 'TV-MC70-S',  1002, '20250207', '20250209', '20250211',  7, 1,  7, 2),

    -- === Second incremental load (load_id = 3) ===
    ('TVSO105', 'TV-JJ17-XL', 1003, '20250306', '20250308', '20250309',  8, 1,  8, 3),  -- products updated in March
    ('TVSO105', 'TV-JJ17-XS', 1003, '20250306', '20250308', '20250309', 22, 2, 11, 3),  -- new customers 1003 and 1004
    ('TVSO106', 'TV-JJ17-XL', 1004, '20250307', '20250309', '20250311', 16, 2,  8, 3),
    ('TVSO106', 'TV-JJ17-XS', 1004, '20250307', '20250309', '20250311', 11, 1, 11, 3);


-- ============================================================
-- DDL: Creating the simTestLoadScenario table
-- ============================================================
-- Table contains test load scenarios for the data simulator.
-- Each scenario defines which data portions should be loaded
-- for each dimension/fact table using bitmask values.
-- ============================================================

CREATE TABLE simTestLoadScenario (
    tls_id                  INTEGER PRIMARY KEY,
    tls_name                TEXT,
    tls_description         TEXT,
    tls_Customer_load_id    INTEGER,
    tls_Product_load_id     INTEGER,
    tls_Sales_load_id       INTEGER
);

-- ============================================================
-- DML: Populating the simTestLoadScenario table
-- ============================================================
-- Scenarios are organized by testing phases:
--   1-3:   Customer dimension testing (C-VT01 to C-VT03)
--   4-6:   Product dimension testing (P-VT01 to P-VT03)
--   7-9:   Sales fact testing (S-VT01 to S-VT03)
--   10:    Clear data scenario (CLR)
--   11-13: All data combined testing (A-VT01 to A-VT03)
-- ============================================================

INSERT INTO simTestLoadScenario 
    (tls_id, tls_name, tls_description, tls_Customer_load_id, tls_Product_load_id, tls_Sales_load_id) 
VALUES
    -- === Customer dimension testing ===
    (1,  'C-VT01', 'Customer valid test initial load',       1, 0, 0),
    (2,  'C-VT02', 'Customer valid test incremental load 1', 3, 0, 0),
    (3,  'C-VT03', 'Customer valid test incremental load 2', 7, 0, 0),

    -- === Product dimension testing ===
    (4,  'P-VT01', 'Product valid test initial load',        0, 1, 0),
    (5,  'P-VT02', 'Product valid test incremental load 1',  0, 2, 0),
    (6,  'P-VT03', 'Product valid test incremental load 2',  0, 3, 0),

    -- === Sales fact testing ===
    (7,  'S-VT01', 'Sales valid test initial load',          0, 0, 1),
    (8,  'S-VT02', 'Sales valid test incremental load 1',    0, 0, 2),
    (9,  'S-VT03', 'Sales valid test incremental load 2',    0, 0, 3),

    -- === Clear data scenario ===
    (10, 'CLR',    'Clear loaded data',                      0, 0, 0),

    -- === All data combined testing ===
    (11, 'A-VT01', 'All data valid test initial load',       1, 1, 1),
    (12, 'A-VT02', 'All data valid test incremental load 1', 3, 2, 2),
    (13, 'A-VT03', 'All data valid test incremental load 2', 7, 3, 3);


-- ============================================================
-- DDL: Creating the simCurrentLoadScenario table
-- ============================================================
-- Singleton table that stores the currently active load scenario.
-- The CHECK constraint on cls_id ensures that only one row can
-- exist in the table (cls_id must always be 1).
-- Switching scenarios is done by updating the tls_id field.
-- ============================================================

CREATE TABLE simCurrentLoadScenario (
    cls_id INTEGER PRIMARY KEY CHECK(cls_id = 1),
    tls_id INTEGER
);

-- ============================================================
-- DML: Populating the simCurrentLoadScenario table
-- ============================================================
-- Initial state: no scenario is active (tls_id = 0).
-- To activate a scenario, update tls_id to the desired tls_id
-- from the simTestLoadScenario table.
-- Example: UPDATE simCurrentLoadScenario SET tls_id = 2;
-- ============================================================

INSERT INTO simCurrentLoadScenario (cls_id, tls_id) 
VALUES 
    (1, 0);  -- default state: no active scenario


-- ============================================================
-- Views: Source endpoints for the Data Simulator
-- ============================================================
-- Each view returns the data portion corresponding to the currently
-- active scenario from simCurrentLoadScenario.
--
-- Two different selection mechanisms are used:
--   * Product / Sales: load_id is a plain scenario part number,
--     so an exact equality join is used.
--   * Customer: load_id is a bitmask block, so bitwise AND is used
--     together with the for_mask exact-match override.
--
-- When the scenario field is 0, the corresponding view returns
-- no rows (no such part exists / bitmask AND returns 0).
-- ============================================================


-- ============================================================
-- View: simProduct
-- ============================================================
-- SCD 2 dimension. Changes are incremental, so the load part number
-- is matched exactly against tls_Product_load_id.
-- Auxiliary column load_id is not exposed to the endpoint.
-- ============================================================

CREATE VIEW simProduct
AS
SELECT 
  pd.prd_id,
  pd.prd_key,
  pd.prd_nm,
  pd.prd_cost,
  pd.prd_start_dt,
  pd.prd_end_dt
FROM productData AS pd
INNER JOIN simTestLoadScenario AS tls
  ON tls.tls_Product_load_id = pd.load_id
INNER JOIN simCurrentLoadScenario AS cls
  ON cls.tls_id = tls.tls_id;


-- ============================================================
-- View: simCustomer
-- ============================================================
-- SCD 1 dimension. The source file is fully reloaded every time,
-- so tls_Customer_load_id is a cumulative bitmask:
--   1 (001) - initial load
--   3 (011) - initial + first incremental load
--   7 (111) - initial + first + second incremental loads
--
-- Selection rule for both fields:
--   (load_id & mask) > 0 AND (for_mask = 0 OR for_mask = mask)
-- for_mask <> 0 means the row belongs to one specific load only.
-- Auxiliary columns load_id and for_mask are not exposed.
-- ============================================================

CREATE VIEW simCustomer
AS
SELECT 
  cd.cst_id,
  cd.cst_key,
  cd.cst_firstname,
  cd.cst_lastname,
  cd.cst_create_date
FROM customerData AS cd
INNER JOIN simTestLoadScenario AS tls
  ON (cd.load_id & tls.tls_Customer_load_id) > 0
  AND (cd.for_mask = 0 OR cd.for_mask = tls.tls_Customer_load_id)
INNER JOIN simCurrentLoadScenario AS cls
  ON cls.tls_id = tls.tls_id;


-- ============================================================
-- View: simSales
-- ============================================================
-- Fact table. Data is only appended, so the load part number
-- is matched exactly against tls_Sales_load_id.
-- Auxiliary column load_id is not exposed to the endpoint.
-- ============================================================

CREATE VIEW simSales
AS
SELECT 
  sd.sls_ord_num,
  sd.sls_prd_key,
  sd.sls_cust_id,
  sd.sls_order_dt,
  sd.sls_ship_dt,
  sd.sls_due_dt,
  sd.sls_sales,
  sd.sls_quantity,
  sd.sls_price
FROM salesData AS sd
INNER JOIN simTestLoadScenario AS tls
  ON tls.tls_Sales_load_id = sd.load_id
INNER JOIN simCurrentLoadScenario AS cls
  ON cls.tls_id = tls.tls_id;


