/* ============================================================
   BRONZE LAYER - DATA QUALITY CHECKS
   PostgreSQL
   ============================================================ */


-- ============================================================
-- Checking bronze.crm_cust_info
-- ============================================================

-- Check for NULLs or Duplicates in Customer ID
-- Expectation: Review duplicate records and NULL IDs

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- Check for Unwanted Spaces in First Name and Last Name
-- Expectation: Review records with extra spaces

SELECT
    cst_firstname,
    cst_lastname
FROM bronze.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);


-- Check Gender Values
-- Review all source values before standardization

SELECT DISTINCT
    cst_gndr
FROM bronze.crm_cust_info
ORDER BY cst_gndr;


-- Check Marital Status Values
-- Review all source values before standardization

SELECT DISTINCT
    cst_marital_status
FROM bronze.crm_cust_info
ORDER BY cst_marital_status;


-- Check Customer Creation Date for NULLs
-- Expectation: Review NULL values

SELECT
    COUNT(*) AS null_create_dates
FROM bronze.crm_cust_info
WHERE cst_create_date IS NULL;



-- ============================================================
-- Checking bronze.crm_prd_info
-- ============================================================

-- Check for NULLs or Duplicates in Product ID
-- Expectation: Review duplicate records and NULL IDs

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- Check for NULL Product IDs
-- Expectation: No Results

SELECT
    prd_id
FROM bronze.crm_prd_info
WHERE prd_id IS NULL;


-- Check for NULL or Negative Product Cost
-- Expectation: Review invalid values

SELECT
    prd_id,
    prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- Check Product Line Values
-- Review all source values before standardization

SELECT DISTINCT
    prd_line
FROM bronze.crm_prd_info
ORDER BY prd_line;


-- Check Product Name for Unwanted Spaces
-- Expectation: Review records with extra spaces

SELECT
    prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);


-- Check Product Start Date for Non-Midnight Time
-- Expectation: False

SELECT EXISTS (
    SELECT 1
    FROM bronze.crm_prd_info
    WHERE prd_start_dt::TIME <> '00:00:00'
) AS has_non_zero_time;



-- ============================================================
-- Checking bronze.crm_sales_details
-- ============================================================

-- Check for Duplicate Order + Product Combinations
-- Expectation: Review duplicate combinations

SELECT
    sls_ord_num,
    sls_prd_key,
    COUNT(*) AS record_count
FROM bronze.crm_sales_details
GROUP BY
    sls_ord_num,
    sls_prd_key
HAVING COUNT(*) > 1;


-- Check for NULL Order Numbers
-- Expectation: No Results

SELECT
    sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num IS NULL;


-- Check for NULL Product Keys
-- Expectation: No Results

SELECT
    sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key IS NULL;


-- Check for Unwanted Spaces in Product Key
-- Expectation: No Results

SELECT
    sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key <> TRIM(sls_prd_key);


-- Check for NULL Customer IDs
-- Expectation: No Results

SELECT
    sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id IS NULL;


-- Check for Invalid Sales Values
-- Expectation: No Results

SELECT
    sls_sales
FROM bronze.crm_sales_details
WHERE sls_sales <= 0;


-- Check for Invalid Quantity Values
-- Expectation: No Results

SELECT
    sls_quantity
FROM bronze.crm_sales_details
WHERE sls_quantity <= 0;


-- Check for Invalid Price Values
-- Expectation: No Results

SELECT
    sls_price
FROM bronze.crm_sales_details
WHERE sls_price <= 0;


-- Check Sales Calculation
-- Sales should equal Quantity * Price
-- Expectation: No Results

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_sales <> sls_quantity * ABS(sls_price);



-- ============================================================
-- Checking bronze.erp_cust_az12
-- ============================================================

-- Check for Duplicate Customer + Gender Combinations
-- Expectation: Review duplicate combinations

SELECT
    cid,
    gen,
    COUNT(*) AS record_count
FROM bronze.erp_cust_az12
GROUP BY
    cid,
    gen
HAVING COUNT(*) > 1;


-- Check for NULL Customer IDs
-- Expectation: Review NULL values

SELECT
    cid
FROM bronze.erp_cust_az12
WHERE cid IS NULL;


-- Check Birthdate for NULLs
-- Expectation: Review NULL values

SELECT
    bdate
FROM bronze.erp_cust_az12
WHERE bdate IS NULL;


-- Check for Future Birthdates
-- Expectation: No Results

SELECT
    cid,
    bdate
FROM bronze.erp_cust_az12
WHERE bdate > CURRENT_DATE;


-- Check Gender Values
-- Review source values before standardization

SELECT DISTINCT
    gen
FROM bronze.erp_cust_az12
ORDER BY gen;



-- ============================================================
-- Checking bronze.erp_loc_a101
-- ============================================================

-- Check Customer ID Mapping
-- Verify cleaned ERP customer IDs match CRM customer keys

SELECT
    REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);


-- Check Country Values
-- Review all source values before standardization

SELECT DISTINCT
    cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;


-- Check for NULL Country Values

SELECT
    cntry
FROM bronze.erp_loc_a101
WHERE cntry IS NULL;


-- Check Country Standardization
-- Review how source values will be transformed

SELECT DISTINCT
    cntry,
    cntry IS NULL AS is_null,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS standardized_country
FROM bronze.erp_loc_a101
ORDER BY cntry;



-- ============================================================
-- Checking bronze.erp_px_cat_g1v2
-- ============================================================

-- Check Category Values
-- Review source values

SELECT DISTINCT
    cat
FROM bronze.erp_px_cat_g1v2
ORDER BY cat;


-- Check Subcategory Values
-- Review source values

SELECT DISTINCT
    subcat
FROM bronze.erp_px_cat_g1v2
ORDER BY subcat;


-- Check Maintenance Values
-- Review source values before loading Silver

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2
ORDER BY maintenance;


-- Check for Unwanted Spaces
-- Expectation: No Results

SELECT
    *
FROM bronze.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);
