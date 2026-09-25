-- Ranking Analysis
-- Top 5 products generating high revenue
SELECT *
FROM (
    SELECT dp.product_number, dp.product_name, SUM(t.sales_amount),
           DENSE_RANK() OVER(ORDER BY SUM(t.sales_amount) DESC) AS rnk
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    GROUP BY dp.product_number, dp.product_name
) t
WHERE rnk < 6;

-- Alternative
SELECT dp.product_number, dp.product_name, SUM(t.sales_amount)
FROM gold.fact_sales t
LEFT JOIN gold.dim_products dp
    ON t.product_key = dp.product_key
GROUP BY dp.product_number, dp.product_name
ORDER BY SUM(t.sales_amount) DESC
LIMIT 5;

-- 5 worst performing products
SELECT *
FROM (
    SELECT dp.product_number, dp.product_name, SUM(t.sales_amount),
           DENSE_RANK() OVER(ORDER BY SUM(t.sales_amount)) AS rnk
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    GROUP BY dp.product_number, dp.product_name
) t
WHERE rnk <= 5;

-- Top 10 customers with high revenue
SELECT c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount)
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales f
    ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY SUM(f.sales_amount) DESC
LIMIT 10;

-- Alternative
SELECT *
FROM (
    SELECT c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount),
           ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount) DESC) AS rnk
    FROM gold.dim_customers c
    LEFT JOIN gold.fact_sales f
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rnk <= 10;

-- Least customers
SELECT *
FROM (
    SELECT c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS revenue,
           ROW_NUMBER() OVER(ORDER BY SUM(f.sales_amount)) AS rnk
    FROM gold.dim_customers c
    LEFT JOIN gold.fact_sales f
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rnk <= 10;

-- Customer with highest orders
SELECT *
FROM (
    SELECT c.customer_key, c.first_name, c.last_name, COUNT(f.order_number) AS orders,
           ROW_NUMBER() OVER(ORDER BY COUNT(f.order_number) DESC) AS rnk
    FROM gold.dim_customers c
    LEFT JOIN gold.fact_sales f
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rnk <= 10;

-- Few orders
SELECT *
FROM (
    SELECT c.customer_key, c.first_name, c.last_name, COUNT(f.order_number) AS orders,
           ROW_NUMBER() OVER(ORDER BY COUNT(f.order_number)) AS rnk
    FROM gold.dim_customers c
    LEFT JOIN gold.fact_sales f
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rnk <= 5;
