# Exploratory Data Analysis (EDA)

After building the Gold layer, I explored the star schema to understand what the data contains and which business questions it can support. The analysis uses only the Gold views and is written entirely in **T-SQL on SQL Server**.

## Data Source

The analysis runs on the Gold layer star schema:

| View | Type | Description |
|------|------|-------------|
| `gold.dim_customers` | Dimension | Customer details such as country, gender and birthdate |
| `gold.dim_products` | Dimension | Product hierarchy: category, subcategory, product |
| `gold.fact_sales` | Fact | Sales transactions: orders, dates, sales amount, quantity, price |

## Analysis Steps

The script is organised in six steps, moving from "what exists" to "who performs best".

### 1. Database Exploration
Lists every object and the columns of the Gold views using `INFORMATION_SCHEMA`. This confirms what is available before writing any analysis.

### 2. Dimensions Exploration
Uses `SELECT DISTINCT` to see the descriptive values in the data: the countries customers come from, and the full product hierarchy (category, subcategory, product). This shows how the data can be sliced.

### 3. Date Exploration
Finds the earliest and latest order dates and the number of years and months covered, plus the oldest and youngest customers by birthdate. This sets the time boundaries for any trend analysis.

### 4. Measures Exploration
Calculates the key business numbers with aggregate functions:

- Total sales
- Items sold
- Average selling price
- Total orders
- Total products
- Total customers
- Customers who have placed an order

A final `UNION ALL` query combines them into a single report.

### 5. Magnitude Analysis
Breaks measures down by dimension (`Aggregate[Measure] BY [Dimension]`):

- Customers by country and gender
- Products by category
- Average cost per category
- Revenue by category
- Revenue per customer
- Items sold per country

This shows where volume and revenue are concentrated.

### 6. Ranking Analysis
Ranks dimensions by a measure (`RANK [Dimension] BY Aggregate[Measure]`):

- Top 5 products and subcategories by revenue
- 5 lowest-selling products
- Top 10 customers by revenue
- 3 customers with the fewest orders

Each ranking is written two ways, with `TOP N` and with the `ROW_NUMBER()` window function, to show both approaches.

## SQL Techniques Used

- `SELECT DISTINCT`
- Aggregate functions: `SUM`, `AVG`, `COUNT(DISTINCT ...)`, `MIN`, `MAX`
- `GROUP BY`
- `LEFT JOIN`
- `DATEDIFF`
- `UNION ALL`
- `TOP N`
- `ROW_NUMBER() OVER (...)`
- Subqueries
- `INFORMATION_SCHEMA`

## Getting Started

1. Build the Gold layer in SQL Server so the `gold.dim_customers`, `gold.dim_products` and `gold.fact_sales` views exist.
2. Open the EDA script in SQL Server Management Studio (or Azure Data Studio).
3. Run it step by step, following the order above.

## Purpose

EDA comes before business analysis. Understanding the structure, time coverage, key measures and top and bottom performers shows what the data can and cannot answer, and which questions are worth analysing in more depth.
