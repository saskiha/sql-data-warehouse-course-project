/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.crm_cust_info
	-- ===============================================================
	
	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>> INSERTING DATA INTO: silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info (
		cst_id, 
		cst_key,
		cst_firstname, 
		cst_lastname,
		cst_marital_status, 
		cst_gndr, 
		cst_create_date)

	SELECT
	cst_id, 
	cst_key,
	TRIM(cst_firstname) AS cst_firstname, -- remove leading and trailing spaces
	TRIM(cst_lastname) AS cst_lastname,  -- remove leading and trailing spaces
	CASE 
		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status, -- normalize marital status values to readable format

	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr, -- normalize gender values to readable format
	cst_create_date
	FROM (
		SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
	)t WHERE flag_last = 1 -- remove duplicates, select the most recent record per customer
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.crm_prd_info
	-- ===============================================================

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info
	PRINT '>> INSERTING DATA INTO: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info (
		prd_id, 
		cat_id, 
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	SELECT
	prd_id, 
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- extract category id
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,-- extract product key
	prd_nm,
	ISNULL(prd_cost, 0) AS prd_cost, -- replace NULLs with zeros
	CASE
		WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
		WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
		WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
		WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
		ELSE 'n/a'
	END AS prd_line,  -- normalize prd_line values to readable format
	CAST(prd_start_dt AS DATE) AS prd_start_dt, -- remove timestamp
	CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
	FROM bronze.crm_prd_info
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.crm_sales_details
	-- ===============================================================

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details
	PRINT '>> INSERTING DATA INTO: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details (
		sls_ord_num, 
		sls_prd_key, 
		sls_cust_id, 
		sls_order_dt, 
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id, 
	CASE
		WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt, -- modify invalid dates

	CASE
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt, -- apply same rule to modify invalid dates that may occur in the future

	CASE
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt, -- apply same rule to modify invalid dates that may occur in the future

	CASE 
		WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales 
	END AS sls_sales, -- handle data inconsistency

	sls_quantity,

	CASE
		WHEN sls_price IS NULL or sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_price -- handle data inconsistency

	FROM bronze.crm_sales_details
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.erp_cust_az12
	-- ===============================================================

	PRINT '------------------------------------------------';
	PRINT 'Loading ERP Tables';
	PRINT '------------------------------------------------';

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12
	PRINT '>> INSERTING DATA INTO: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12(
		cid, 
		bdate, 
		gen
	)
	SELECT
	-- remove NAS from cid
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	-- replace wrong bdates with NULL
	CASE
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate,
	-- standardize the value gender for better readability
	CASE
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
	FROM bronze.erp_cust_az12
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.erp_loc_a101
	-- ===============================================================

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101
	PRINT '>> INSERTING DATA INTO: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101(
		cid,
		cntry
	)
	SELECT 
	REPLACE(cid, '-', '') cid, -- remove the '-' in cid

	CASE
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry -- normalize and handle missing or blank country codes
	FROM bronze.erp_loc_a101
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	-- ===============================================================
	-- TRANSFORM & LOAD silver.erp_px_cat_g1v2
	-- ===============================================================

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2
	PRINT '>> INSERTING DATA INTO: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
	)
	SELECT
	id,
	cat,
	subcat,
	maintenance
	FROM bronze.erp_px_cat_g1v2;
	SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    PRINT '>> -------------';

	SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
