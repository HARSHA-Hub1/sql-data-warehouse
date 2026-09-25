-- Date Range Exploration
SELECT MIN(birthdate) AS old_customer, MAX(birthdate) AS latest_customer
FROM gold.dim_customers dc;
