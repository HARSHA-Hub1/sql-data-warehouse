-- Data Segmentation
WITH customers_level AS (
    SELECT dc.customer_key,
           CONCAT(dc.first_name, ' ', dc.last_name) AS name,
           AGE(MAX(t.order_date), MIN(t.order_date)) AS span,
           CASE
               WHEN AGE(MAX(t.order_date), MIN(t.order_date)) >= INTERVAL '12 months'
                    AND SUM(t.sales_amount) > 5000 THEN 'VIP'
               WHEN AGE(MAX(t.order_date), MIN(t.order_date)) >= INTERVAL '12 months'
                    AND SUM(t.sales_amount) <= 5000 THEN 'regular'
               ELSE 'New'
           END AS level
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_customers dc
        ON t.customer_key = dc.customer_key
    GROUP BY dc.customer_key, dc.first_name, dc.last_name
)
SELECT level, COUNT(*)
FROM customers_level
GROUP BY level;
