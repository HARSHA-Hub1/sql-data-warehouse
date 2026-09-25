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
GROUP BY order_year, order_month, order_day
ORDER BY order_year, order_month, order_day;
