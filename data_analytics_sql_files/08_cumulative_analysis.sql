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
