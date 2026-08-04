
-- ==================================================
-- DATA QUALITY CHECK FOR TABLE: bronze.crm_cust_info
-- ===================================================


-- Check for NULLs or Duplicates in Primary Key
-- Expection: No Result

SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Remove Duplicates
SELECT
*
FROM (
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
)t WHERE flag_last = 1

-- Check for unwanted Spaces
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

-- ==================================================
-- DATA QUALITY CHECK FOR TABLE: bronze.crm_prd_info
-- ===================================================

SELECT
prd_id, 
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

-- Check for duplicates within primary key
SELECT
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for duplicates within prd_key
SELECT
prd_key,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_key
HAVING COUNT(*) > 1 OR prd_key IS NULL

-- Check background of duplicate
-- Duplicates because of product history
SELECT
*
FROM bronze.crm_prd_info
WHERE prd_key = 'AC-HE-HL-U509'

-- Check for unwanted spaces
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLs or negative Numbers
SELECT
prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- Check for Invalid date Orders
SELECT
*
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- Replace invalid date orders with values from the next row within a window -1
SELECT
prd_id, 
prd_key, 
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')


-- ==================================================
-- DATA QUALITY CHECK FOR TABLE: bronze.crm_sales_details
-- ===================================================

-- Check for invalid dates
SELECT
NULLIF(sls_order_dt, 0) sls_order_dt -- replace 0 with NULLs
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101

-- check data consistency
SELECT DISTINCT
sls_sales, 
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-- ==================================================
-- DATA QUALITY CHECK FOR TABLE: bronze.erp_loc_a101
-- ===================================================

-- remove '-' in cid with 
SELECT
REPLACE(cid, '-', '') cid
FROM bronze.erp_loc_a101
-- check integrity for joining tables
WHERE REPLACE(cid, '-', '') NOT IN 
(SELECT cst_key FROM silver.crm_cust_info)

-- Data standardization & consistency
SELECT DISTINCT
cntry
FROM bronze.erp_loc_a101

-- ==================================================
-- DATA QUALITY CHECK FOR TABLE: bronze.erp_px_cat_g1v2
-- ===================================================

SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2

-- Check for unwanted spaces
SELECT 
cat
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat)

-- Check Data Standardization & Consistency

SELECT DISTINCT
cat, -- subcat, -- maintenance
FROM bronze.erp_px_cat_g1v2


