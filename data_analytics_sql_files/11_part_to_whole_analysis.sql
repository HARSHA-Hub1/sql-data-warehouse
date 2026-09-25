-- Part to Whole Analysis
WITH category_sales AS (
    SELECT dp.category, SUM(t.sales_amount) AS total_sales
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    GROUP BY dp.category
)
SELECT category,
       total_sales,
       SUM(total_sales) OVER() AS overall_sales,
       CONCAT(ROUND((total_sales / SUM(total_sales) OVER()) * 100, 2)::VARCHAR, '%') AS percent
FROM category_sales;

WITH category_counts AS (
    SELECT dp.category, SUM(t.quantity) AS total_quantity
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    GROUP BY dp.category
)
SELECT category,
       total_quantity,
       SUM(total_quantity) OVER() AS overall_quantity,
       (total_quantity / SUM(total_quantity) OVER()) * 100 AS percent
FROM category_counts;

WITH category_counts AS (
    SELECT dp.category, COUNT(order_number) AS total_orders
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    GROUP BY dp.category
)
SELECT category,
       total_orders,
       SUM(total_orders) OVER() AS overall_orders,
       (total_orders / SUM(total_orders) OVER()) * 100 AS percent
FROM category_counts;
