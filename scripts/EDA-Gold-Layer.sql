/*
===============================================================================
Script Name : eda_gold_layer.sql
Purpose     : Exploratory Data Analysis (EDA) on the Gold layer views.
              Understand what data is available before answering business
              questions: objects, dimensions, date range, key measures,
              magnitude (measure by dimension) and ranking (top / bottom).
Source      : gold.dim_customers, gold.dim_products, gold.fact_sales
Operational : Read-only. Contains only SELECT statements.
Sections    : 1. Database exploration
              2. Dimensions exploration
              3. Date exploration
              4. Measures exploration
              5. Magnitude analysis   -> Aggregate[Measure] BY [Dimension]
              6. Ranking analysis     -> RANK [Dimension] BY Aggregate[Measure]
===============================================================================
*/

USE DataWarehouse;
GO

--=====================================================--
-- 1. DATABASE EXPLORATION
--=====================================================--

-- Explore all the objects in the database
SELECT *
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA;

-- Explore all columns of one object (change the name to explore another)
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


--=====================================================--
-- 2. DIMENSIONS EXPLORATION
--=====================================================--

-- Which countries do our customers come from?
SELECT DISTINCT country
FROM gold.dim_customers;

-- Explore the product hierarchy: category > subcategory > product
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;


--=====================================================--
-- 3. DATE EXPLORATION
--=====================================================--

-- Earliest and latest order dates, and how many years / months of sales exist
SELECT
    MIN(order_date)                              AS earliest_date,
    MAX(order_date)                              AS latest_date,
    DATEDIFF(YEAR,  MIN(order_date), MAX(order_date)) AS span_years,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS span_months
FROM gold.fact_sales;

-- Oldest and youngest customer (by birthdate)
SELECT
    MIN(birthdate)                               AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE())    AS oldest_age,
    MAX(birthdate)                               AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE())    AS youngest_age
FROM gold.dim_customers;


--=====================================================--
-- 4. MEASURES EXPLORATION (aggregate functions)
--=====================================================--

-- Total sales, items sold, average selling price, total orders
-- NOTE: price is stored as INT, so AVG(price) returns a whole number.
--       Use AVG(CAST(price AS DECIMAL(18,2))) if you need decimals.
SELECT
    SUM(sales)                   AS total_sales,
    SUM(quantity)                AS items_sold,
    AVG(price)                   AS avg_selling_price,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Total number of products
SELECT COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products;

-- Total number of customers
SELECT COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers;

-- Total number of customers who have placed an order
SELECT COUNT(DISTINCT customer_key) AS customers_who_ordered
FROM gold.fact_sales;

-- All key measures in one report
SELECT 'Total Sales' AS measure_name, SUM(sales) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_key)
FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT customer_key)
FROM gold.dim_customers
UNION ALL
SELECT 'Customers Who Ordered', COUNT(DISTINCT customer_key)
FROM gold.fact_sales;


--=====================================================--
-- 5. MAGNITUDE ANALYSIS
--    Formula: Aggregate[Measure] BY [Dimension]
--=====================================================--

-- Total customers by country
SELECT
    country,
    COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Total customers by gender
SELECT
    gender,
    COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Total products by category
SELECT
    category,
    COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average cost in each category
-- NOTE: cost is stored as INT, so AVG(cost) returns a whole number.
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- Total revenue generated for each category
SELECT
    pr.category,
    SUM(ft.sales) AS total_revenue
FROM gold.fact_sales ft
LEFT JOIN gold.dim_products pr
    ON pr.product_key = ft.product_key
GROUP BY pr.category
ORDER BY total_revenue DESC;

-- Total revenue generated by each customer
SELECT
    cu.customer_key,
    cu.first_name,
    cu.last_name,
    SUM(ft.sales) AS total_revenue
FROM gold.fact_sales ft
LEFT JOIN gold.dim_customers cu
    ON cu.customer_key = ft.customer_key
GROUP BY
    cu.customer_key,
    cu.first_name,
    cu.last_name
ORDER BY total_revenue DESC;

-- Distribution of sold items across countries
SELECT
    cu.country,
    SUM(ft.quantity) AS total_quantity
FROM gold.fact_sales ft
LEFT JOIN gold.dim_customers cu
    ON ft.customer_key = cu.customer_key
GROUP BY cu.country
ORDER BY total_quantity DESC;


--=====================================================--
-- 6. RANKING ANALYSIS
--    Formula: RANK [Dimension] BY Aggregate[Measure]
--    Two methods are shown: TOP N, and ROW_NUMBER() window function.
--=====================================================--

-- Which 5 products generate the highest revenue? (Method 1: TOP N)
SELECT TOP 5
    p.product_key,
    p.product_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_key,
    p.product_name
ORDER BY total_sales DESC;

-- Which 5 subcategories generate the highest revenue?
SELECT TOP 5
    p.subcategory,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_sales DESC;

-- Which 5 products generate the highest revenue? (Method 2: ROW_NUMBER)
SELECT *
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales) DESC) AS ranking,
        p.product_name,
        SUM(f.sales) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_name
) t
WHERE ranking <= 5;

-- What are the 5 worst-performing products in terms of sales?
-- NOTE: products with no sales at all do not appear here, because the
--       query starts from the fact table.
SELECT TOP 5
    p.product_key,
    p.category,
    p.subcategory,
    p.product_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_key,
    p.category,
    p.subcategory,
    p.product_name
ORDER BY total_sales ASC;

-- Top 10 customers who generated the highest revenue (Method 1: ROW_NUMBER)
SELECT *
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales) DESC) AS ranking,
        c.customer_key,
        c.first_name,
        c.last_name,
        SUM(f.sales) AS total_revenue
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.first_name,
        c.last_name
) t
WHERE ranking <= 10;

-- Top 10 customers who generated the highest revenue (Method 2: TOP N)
SELECT TOP 10
    cu.customer_key,
    cu.first_name,
    cu.last_name,
    SUM(ft.sales) AS total_revenue
FROM gold.fact_sales ft
LEFT JOIN gold.dim_customers cu
    ON cu.customer_key = ft.customer_key
GROUP BY
    cu.customer_key,
    cu.first_name,
    cu.last_name
ORDER BY total_revenue DESC;

-- 3 customers with the fewest orders placed (Method 1: ROW_NUMBER)
-- NOTE: many customers may share the same low order count (for example 1),
--       so which 3 rows appear can be arbitrary when there are ties.
SELECT *
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_number)) AS ranking,
        c.customer_key,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT order_number) AS total_orders
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.first_name,
        c.last_name
) t
WHERE ranking <= 3;

-- 3 customers with the fewest orders placed (Method 2: TOP N)
SELECT TOP 3
    cu.customer_key,
    cu.first_name,
    cu.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales ft
LEFT JOIN gold.dim_customers cu
    ON cu.customer_key = ft.customer_key
GROUP BY
    cu.customer_key,
    cu.first_name,
    cu.last_name
ORDER BY total_orders ASC;
