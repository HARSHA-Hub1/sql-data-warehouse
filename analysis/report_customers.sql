/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
CREATE OR REPLACE VIEW gold.report_customers AS
WITH base_query AS (
    SELECT
        f.order_number,
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
    SELECT
        customer_key,
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
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)
SELECT
    customer_key,
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
    total_sales::NUMERIC / NULLIF(total_orders, 0) AS avg_order_value,
    total_quantity,
    total_products,
    lifespan,
    total_sales::NUMERIC / NULLIF(lifespan, 0) AS monthly_spend
FROM customer_aggregation;
