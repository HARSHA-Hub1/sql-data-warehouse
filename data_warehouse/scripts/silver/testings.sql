/* ============================================================
   SILVER LAYER - DATA QUALITY CHECKS
   PostgreSQL
   ============================================================ */


-- ============================================================
-- Checking silver.crm_cust_info
-- ============================================================

-- Check for NULLs or Duplicates in Customer ID
-- Expectation: No Results

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- Check for Unwanted Spaces in Customer Key
-- Expectation: No Results

SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key);


-- Check for Unwanted Spaces in First and Last Names
-- Expectation: No Results

SELECT
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);


-- Check Gender Standardization
-- Expectation: Only Male, Female and n/a

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info
ORDER BY cst_gndr;


-- Check Marital Status Standardization
-- Expectation: Only Single, Married and n/a

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info
ORDER BY cst_marital_status;


-- Check for NULL Customer Creation Dates
-- Expectation: No Results

SELECT
    cst_id,
    cst_create_date
FROM silver.crm_cust_info
WHERE cst_create_date IS NULL;



-- ============================================================
-- Checking silver.crm_prd_info
-- ============================================================

-- Check for NULLs or Duplicates in Product ID
-- Expectation: No Results

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- Check for Unwanted Spaces in Product Name
-- Expectation: No Results

SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);


-- Check for NULL or Negative Product Cost
-- Expectation: No Results

SELECT
    prd_id,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- Check Product Line Standardization
-- Expectation: Only valid standardized values

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info
ORDER BY prd_line;


-- Check Product Start/End Date Logic
-- Expectation: No Results

SELECT
    prd_id,
    prd_key,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- Check Product Start Dates for NULLs
-- Expectation: No Results

SELECT
    prd_id,
    prd_start_dt
FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL;



-- ============================================================
-- Checking silver.crm_sales_details
-- ============================================================

-- Check for NULL Order/Product Keys
-- Expectation: No Results

SELECT
    sls_ord_num,
    sls_prd_key
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL
   OR sls_prd_key IS NULL;


-- Check for Unwanted Spaces in Product Key
-- Expectation: No Results

SELECT
    sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key <> TRIM(sls_prd_key);


-- Check for NULL Customer IDs
-- Expectation: No Results

SELECT
    sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id IS NULL;


-- Check for Invalid Sales Dates
-- Expectation: No Results

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL
   OR sls_ship_dt IS NULL
   OR sls_due_dt IS NULL;


-- Check Date Order
-- Order Date should not be after Ship Date or Due Date
-- Expectation: No Results

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


-- Check Sales Data Consistency
-- Sales should equal Quantity * Price
-- Expectation: No Results

SELECT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


-- ------------------------------------------------------------
-- Product Referential Integrity
-- ------------------------------------------------------------

-- Check using NOT IN
-- Expectation: No Results

SELECT
    sls_ord_num,
    sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (
    SELECT prd_key
    FROM silver.crm_prd_info
);


-- Check using LEFT JOIN
-- Expectation: No Results

SELECT
    csd.sls_ord_num,
    csd.sls_prd_key
FROM silver.crm_sales_details csd
LEFT JOIN silver.crm_prd_info cpi
    ON csd.sls_prd_key = cpi.prd_key
WHERE cpi.prd_key IS NULL;


-- Check using NOT EXISTS
-- Expectation: No Results

SELECT
    csd.sls_ord_num,
    csd.sls_prd_key
FROM silver.crm_sales_details csd
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.crm_prd_info cpi
    WHERE cpi.prd_key = csd.sls_prd_key
);


-- ------------------------------------------------------------
-- Customer Referential Integrity
-- ------------------------------------------------------------

-- Check using NOT IN
-- Expectation: No Results

SELECT
    sls_ord_num,
    sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id
    FROM silver.crm_cust_info
);


-- Check using LEFT JOIN
-- Expectation: No Results

SELECT
    csd.sls_ord_num,
    csd.sls_cust_id
FROM silver.crm_sales_details csd
LEFT JOIN silver.crm_cust_info cci
    ON csd.sls_cust_id = cci.cst_id
WHERE cci.cst_id IS NULL;


-- Check using NOT EXISTS
-- Expectation: No Results

SELECT
    csd.sls_ord_num,
    csd.sls_cust_id
FROM silver.crm_sales_details csd
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.crm_cust_info cci
    WHERE cci.cst_id = csd.sls_cust_id
);



-- ============================================================
-- Checking silver.erp_cust_az12
-- ============================================================

-- Check for Duplicate Customer + Gender Records
-- Expectation: No unexpected duplicates

SELECT
    cid,
    gen,
    COUNT(*) AS record_count
FROM silver.erp_cust_az12
GROUP BY cid, gen
HAVING COUNT(*) > 1;


-- Check for NULL Customer IDs
-- Expectation: No Results

SELECT
    cid
FROM silver.erp_cust_az12
WHERE cid IS NULL;


-- Check Birthdates for NULLs
-- Review NULL values after cleansing

SELECT
    bdate
FROM silver.erp_cust_az12
WHERE bdate IS NULL;


-- Check for Future Birthdates
-- Expectation: No Results

SELECT
    cid,
    bdate
FROM silver.erp_cust_az12
WHERE bdate > CURRENT_DATE;


-- Check Birthdate Range
-- Expectation: Birthdates should be within the expected range

SELECT
    cid,
    bdate
FROM silver.erp_cust_az12
WHERE bdate < DATE '1924-01-01'
   OR bdate > CURRENT_DATE;


-- Check Gender Standardization
-- Expectation: Only Male, Female and n/a

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12
ORDER BY gen;



-- ============================================================
-- Checking silver.erp_loc_a101
-- ============================================================

-- Check Country Standardization
-- Review all standardized country values

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- Check for NULL Customer IDs
-- Expectation: No Results

SELECT
    cid
FROM silver.erp_loc_a101
WHERE cid IS NULL;


-- Check for Unwanted Spaces in Country
-- Expectation: No Results

SELECT
    cntry
FROM silver.erp_loc_a101
WHERE cntry <> TRIM(cntry);



-- ============================================================
-- Checking silver.erp_px_cat_g1v2
-- ============================================================

-- Check for Unwanted Spaces
-- Expectation: No Results

SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);


-- Check Maintenance Standardization
-- Review all values

SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2
ORDER BY maintenance;


-- Check Category Values
-- Review distinct category values

SELECT DISTINCT
    cat
FROM silver.erp_px_cat_g1v2
ORDER BY cat;


-- Check Subcategory Values
-- Review distinct subcategory values

SELECT DISTINCT
    subcat
FROM silver.erp_px_cat_g1v2
ORDER BY subcat;
