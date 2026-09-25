-- Advanced Data Analysis

-- 08_cumulative_analysis.sql
-- Cumulative Analysis
-- Running total sales by month
SELECT DATE_TRUNC('month', order_date) AS order_date,
       SUM(sales_amount) AS sales,
       SUM(SUM(sales_amount)) OVER(ORDER BY DATE_TRUNC('month', order_date)) AS running_total
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_date;

-- Running total using a subquery
SELECT order_date, total_sales,
       SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales
FROM (
    SELECT DATE_TRUNC('month', order_date) AS order_date,
           SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', order_date)
) t
ORDER BY order_date;

-- Partition by month
SELECT DATE_TRUNC('month', order_date) AS order_date,
       SUM(sales_amount) AS sales,
       SUM(SUM(sales_amount)) OVER(
           PARTITION BY DATE_TRUNC('month', order_date)
           ORDER BY DATE_TRUNC('month', order_date)
       ) AS running_total
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_date;

-- Running total and cumulative average
SELECT DATE_TRUNC('month', order_date) AS order_date,
       SUM(sales_amount) AS sales,
       SUM(SUM(sales_amount)) OVER(ORDER BY DATE_TRUNC('month', order_date)) AS running_total,
       AVG(AVG(price)) OVER(ORDER BY DATE_TRUNC('month', order_date)) AS moving_avg
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_date;

-- Moving average by year
SELECT DATE_TRUNC('year', order_date) AS order_date,
       AVG(price) AS avg_price,
       AVG(AVG(price)) OVER(ORDER BY DATE_TRUNC('year', order_date)) AS moving_avg_price
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('year', order_date)
ORDER BY order_date;

-- Running total and moving average using a subquery
SELECT order_date,
       SUM(total_sales) OVER(ORDER BY order_date) AS running_total,
       AVG(avg_price) OVER(ORDER BY order_date) AS moving_avg
FROM (
    SELECT DATE_TRUNC('year', order_date) AS order_date,
           SUM(sales_amount) AS total_sales,
           AVG(price) AS avg_price
    FROM gold.fact_sales t
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('year', order_date)
) t
ORDER BY order_date;

-- 09_performance_analysis.sql
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

-- 10_data_segmentation.sql
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

-- 11_part_to_whole_analysis.sql
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

-- 12_report_customers.sql
-- Customer Report
WITH base_query AS (
    SELECT f.order_number,
           f.product_key,
           f.sales_amount,
           f.order_date,
           f.quantity,
           f.customer_key,
           dc.customer_number,
           CONCAT(dc.first_name, ' ', dc.last_name) AS customer_name,
           EXTRACT(YEAR FROM AGE(CURRENT_DATE, dc.birthdate)) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers dc
        ON dc.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS (
    SELECT customer_key,
           customer_number,
           customer_name,
           age,
           COUNT(order_number) AS total_orders,
           SUM(sales_amount) AS total_sales,
           SUM(quantity) AS total_quantity,
           COUNT(product_key) AS total_products,
           (
               EXTRACT(YEAR FROM MAX(order_date)) -
               EXTRACT(YEAR FROM MIN(order_date))
           ) * 12 +
           (
               EXTRACT(MONTH FROM MAX(order_date)) -
               EXTRACT(MONTH FROM MIN(order_date))
           ) AS lifespan,
           MIN(order_date) AS first_order,
           MAX(order_date) AS last_order
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT customer_key,
       customer_number,
       customer_name,
       age,
       CASE
           WHEN age < 20 THEN 'under 20'
           WHEN age BETWEEN 20 AND 29 THEN '20-29'
           WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
           WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
           ELSE '50 and above'
       END AS age_group,
       CASE
           WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
           WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'regular'
           ELSE 'new'
       END AS customer_segment,
       last_order,
       (
           EXTRACT(YEAR FROM CURRENT_DATE) -
           EXTRACT(YEAR FROM last_order)
       ) * 12 +
       (
           EXTRACT(MONTH FROM CURRENT_DATE) -
           EXTRACT(MONTH FROM last_order)
       ) AS recency,
       total_orders,
       total_sales,
       total_quantity,
       total_products,
       lifespan,
       total_sales / NULLIF(total_orders, 0) AS avg_order_value
FROM customer_aggregation;

-- 13_report_products.sql
-- Product Report
WITH base_query AS (
    SELECT t.order_number,
           t.product_key,
           t.customer_key,
           t.order_date,
           t.sales_amount,
           t.quantity,
           dp.product_name,
           dp.category,
           dp.subcategory,
           dp.cost
    FROM gold.fact_sales t
    LEFT JOIN gold.dim_products dp
        ON t.product_key = dp.product_key
    WHERE t.order_date IS NOT NULL
),
product_aggregations AS (
    SELECT product_key,
           product_name,
           category,
           subcategory,
           cost,
           (
               EXTRACT(YEAR FROM MAX(order_date)) -
               EXTRACT(YEAR FROM MIN(order_date))
           ) * 12 +
           (
               EXTRACT(MONTH FROM MAX(order_date)) -
               EXTRACT(MONTH FROM MIN(order_date))
           ) AS lifespan,
           MAX(order_date) AS last_sale_date,
           COUNT(DISTINCT order_number) AS total_orders,
           COUNT(DISTINCT customer_key) AS total_customers,
           SUM(sales_amount) AS total_sales,
           SUM(quantity) AS total_quantity,
           ROUND(AVG(sales_amount / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT product_key,
       product_name,
       category,
       subcategory,
       cost,
       lifespan,
       last_sale_date,
       total_orders,
       total_customers,
       total_sales,
       total_quantity,
       avg_selling_price,
       CASE
           WHEN total_sales > 50000 THEN 'High Performer'
           WHEN total_sales >= 10000 THEN 'Mid Range'
           ELSE 'Low Performer'
       END AS product_segment,
       CASE
           WHEN total_orders = 0 THEN 0
           ELSE total_sales / total_orders
       END AS avg_order_revenue,
       CASE
           WHEN lifespan = 0 THEN 0
           ELSE total_sales / lifespan
       END AS avg_monthly_revenue
FROM product_aggregations;
