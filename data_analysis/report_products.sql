/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
-- Base query: get product metadata
CREATE OR REPLACE VIEW gold.report_products AS
WITH base_query AS (
    SELECT
        t.order_number,
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
-- Perform product aggregations
product_aggregations AS (
    SELECT
        product_key,
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
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
-- Final segmentation and calculated metrics
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    lifespan,
    last_sale_date,
    (
        EXTRACT(YEAR FROM CURRENT_DATE) -
        EXTRACT(YEAR FROM last_sale_date)
    ) * 12 +
    (
        EXTRACT(MONTH FROM CURRENT_DATE) -
        EXTRACT(MONTH FROM last_sale_date)
    ) AS recency,
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
    total_sales::NUMERIC / NULLIF(total_orders, 0) AS avg_order_revenue,
    total_sales::NUMERIC / NULLIF(lifespan, 0) AS avg_monthly_revenue
FROM product_aggregations;
