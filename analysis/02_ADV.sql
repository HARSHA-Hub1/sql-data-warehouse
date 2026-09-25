-- Advanced Data Analysis


-- Change Over Time Analysis
-- Per day trends of sales
SELECT order_date, SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
GROUP BY order_date
ORDER BY order_date;

-- Per year sales trends
SELECT EXTRACT(YEAR FROM order_date) AS order_year, SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY order_year;

-- DATE_TRUNC by year
SELECT DATE_TRUNC('year', order_date) AS order_year, SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY order_year;

-- DATE_TRUNC by month
SELECT DATE_TRUNC('month', order_date) AS order_month, SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY order_month
ORDER BY order_month;

-- TO_CHAR by month
SELECT TO_CHAR(order_date, 'YYYY-Mon') AS order_month, SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'YYYY-Mon')
ORDER BY TO_CHAR(order_date, 'YYYY-Mon');

-- Year, month and day
SELECT EXTRACT(YEAR FROM order_date) AS order_year,
       EXTRACT(MONTH FROM order_date) AS order_month,
       EXTRACT(DAY FROM order_date) AS order_day,
       SUM(sales_amount) AS total_sales
FROM gold.fact_sales t
WHERE order_date IS NOT NULL

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

