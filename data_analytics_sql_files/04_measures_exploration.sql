-- Measures Exploration
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales t;

SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales t;

SELECT AVG(price) AS average_price
FROM gold.fact_sales t;

-- Report
SELECT 'Total sales' AS measure_name, SUM(sales_amount) AS measure_value
FROM gold.fact_sales t
UNION ALL
SELECT 'Total Quantity', SUM(quantity)
FROM gold.fact_sales t
UNION ALL
SELECT 'Average Price', AVG(price)
FROM gold.fact_sales t
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number)
FROM gold.fact_sales t
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_id)
FROM gold.dim_products dp
UNION ALL
SELECT 'Total customers', COUNT(DISTINCT customer_key)
FROM gold.fact_sales t;
