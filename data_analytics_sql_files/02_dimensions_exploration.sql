-- Dimensions Exploration
SELECT MIN(birthdate) AS old_customer, MAX(birthdate) AS latest_customer,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, MIN(birthdate))) AS age
FROM gold.dim_customers dc;

SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales t;

SELECT COUNT(DISTINCT product_id) AS total_products
FROM gold.dim_products dp;

SELECT COUNT(DISTINCT product_key) AS sold_products
FROM gold.fact_sales t;

SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM gold.dim_customers dc;

SELECT COUNT(DISTINCT customer_key) AS active_customers
FROM gold.fact_sales t;

SELECT product_key
FROM gold.dim_products dp
WHERE product_key NOT IN (
    SELECT product_key
    FROM gold.fact_sales t
);
