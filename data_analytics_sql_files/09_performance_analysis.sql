-- Performance Analysis
WITH yearly_sales AS (
    SELECT EXTRACT(YEAR FROM t.order_date) AS order_year,
           dp.product_name,
           SUM(t.sales_amount) AS current_sales
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    WHERE t.order_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM t.order_date), dp.product_name
)
SELECT order_year,
       product_name,
       current_sales,
       LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS prev_sales,
       AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
       CASE
           WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'below avg'
           WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'above avg'
           ELSE 'avg'
       END AS avg_performance,
       CASE
           WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'decreasing'
           WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'increasing'
           ELSE 'same'
       END AS sales_performance
FROM yearly_sales
ORDER BY product_name, order_year;

WITH monthly_sales AS (
    SELECT EXTRACT(MONTH FROM t.order_date) AS order_month,
           dp.product_name,
           SUM(t.sales_amount) AS current_sales
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    WHERE t.order_date IS NOT NULL
    GROUP BY EXTRACT(MONTH FROM t.order_date), dp.product_name
)
SELECT order_month,
       product_name,
       current_sales,
       LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_month) AS prev_sales,
       AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
       CASE
           WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'below avg'
           WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'above avg'
           ELSE 'avg'
       END AS avg_performance,
       CASE
           WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_month) < 0 THEN 'decreasing'
           WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_month) > 0 THEN 'increasing'
           ELSE 'same'
       END AS sales_performance
FROM monthly_sales
ORDER BY product_name, order_month;
