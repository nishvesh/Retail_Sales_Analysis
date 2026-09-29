/*
====================================================================
RETAIL SALES DATA ANALYSIS - FINAL SQL SCRIPT
====================================================================

Project: Retail Sales Data Analysis
Database: retail_analysis_db
Main table: retail

PURPOSE
-------
This file contains the final SQL analysis used for the project.
The queries are arranged as a flow:

1. Connect and inspect the data
2. Validate data quality
3. Create project KPIs
4. Analyze categories, regions and segments
5. Analyze customers and products
6. Analyze shipping
7. Analyze time-based sales
8. Perform advanced analysis with CTEs and window functions
9. Use joins for relational analysis
10. Create analysis outputs useful for Power BI/reporting

The comments explain what each important query does.

Note:
- The dataset contains Sales but does not contain Profit.
- Therefore, this script does not perform profit analysis.
- Queries use MySQL syntax.
====================================================================
*/


/* ================================================================
   1. DATABASE AND TABLE CHECK
   ================================================================ */

USE retail_analysis_db;

-- Check which tables are available in the database.
SHOW TABLES;

-- Check the structure, column names and data types.
DESCRIBE retail;

-- Check the total number of records.
SELECT
    COUNT(*) AS Total_Records
FROM retail;

-- Preview the first 100 rows before starting the analysis.
SELECT *
FROM retail
LIMIT 100;


/* ================================================================
   2. DATA QUALITY CHECKS
   ================================================================ */

-- Check for missing Postal Code values.
-- This identifies rows where the postal code is unavailable.
SELECT
    COUNT(*) AS Missing_Postal_Codes
FROM retail
WHERE Postal_Code IS NULL;

-- Check for duplicate Row_ID values.
-- Row_ID is expected to identify individual records.
SELECT
    Row_ID,
    COUNT(*) AS Duplicate_Count
FROM retail
GROUP BY Row_ID
HAVING COUNT(*) > 1;

-- Check the date range of the dataset.
SELECT
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM retail;

-- Check the number of distinct values in important business dimensions.
SELECT
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    COUNT(DISTINCT Product_ID) AS Total_Products,
    COUNT(DISTINCT Category) AS Total_Categories,
    COUNT(DISTINCT Region) AS Total_Regions,
    COUNT(DISTINCT Segment) AS Total_Segments,
    COUNT(DISTINCT Ship_Mode) AS Total_Ship_Modes
FROM retail;


/* ================================================================
   3. MAIN PROJECT KPIs
   ================================================================ */

-- PROJECT KPI QUERY
-- Returns the main numbers used in the final project report
-- and the Power BI dashboard.
SELECT
    ROUND(SUM(Sales), 2) AS Total_Sales,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    COUNT(DISTINCT Product_ID) AS Total_Products,
    ROUND(
        SUM(Sales) / COUNT(DISTINCT Order_ID),
        2
    ) AS Average_Order_Value,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 2) AS Average_Ship_Days
FROM retail;


/* ================================================================
   4. CATEGORY ANALYSIS
   ================================================================ */

-- Compare total sales across categories.
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Category
ORDER BY Total_Sales DESC;

-- Detailed category performance.
-- Shows sales, average transaction sales, highest and lowest
-- individual sales values, order count and AOV.
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(AVG(Sales), 2) AS Average_Sale,
    ROUND(MAX(Sales), 2) AS Max_Sale,
    ROUND(MIN(Sales), 2) AS Min_Sale,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(
        SUM(Sales) / COUNT(DISTINCT Order_ID),
        2
    ) AS AOV
FROM retail
GROUP BY Category
ORDER BY Total_Sales DESC;

-- Calculate each category's percentage contribution to total sales.
WITH category_sales AS (
    SELECT
        Category,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Category
)
SELECT
    Category,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        Total_Sales / SUM(Total_Sales) OVER () * 100,
        2
    ) AS Sales_Percentage
FROM category_sales
ORDER BY Total_Sales DESC;


/* ================================================================
   5. REGION ANALYSIS
   ================================================================ */

-- Compare total sales across regions.
SELECT
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Region and category comparison.
-- This produces a pivot-like result using conditional aggregation.
SELECT
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(CASE
        WHEN Category = 'Furniture' THEN Sales ELSE 0
    END), 2) AS Furniture_Sales,
    ROUND(SUM(CASE
        WHEN Category = 'Office Supplies' THEN Sales ELSE 0
    END), 2) AS Office_Supplies_Sales,
    ROUND(SUM(CASE
        WHEN Category = 'Technology' THEN Sales ELSE 0
    END), 2) AS Technology_Sales
FROM retail
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Find states with sales greater than $50,000.
SELECT
    State,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY State
HAVING SUM(Sales) > 50000
ORDER BY Total_Sales DESC;


/* ================================================================
   6. SEGMENT ANALYSIS
   ================================================================ */

-- Compare sales and unique orders for each customer segment.
SELECT
    Segment,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM retail
GROUP BY Segment
ORDER BY Total_Sales DESC;

-- Find segments with sales above $400,000.
SELECT
    Segment,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM retail
GROUP BY Segment
HAVING SUM(Sales) > 400000
ORDER BY Total_Sales DESC;


/* ================================================================
   7. CUSTOMER ANALYSIS
   ================================================================ */

-- Calculate total sales for every customer.
-- This creates the base customer-level analysis.
SELECT
    Customer_ID,
    Customer_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Sales DESC;

-- Find customers whose total sales are greater than $10,000.
SELECT
    Customer_ID,
    Customer_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Customer_ID, Customer_Name
HAVING SUM(Sales) > 10000
ORDER BY Total_Sales DESC;

-- Rank customers from highest to lowest sales.
WITH customer_sales AS (
    SELECT
        Customer_ID,
        Customer_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Customer_ID, Customer_Name
)
SELECT
    Customer_ID,
    Customer_Name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    RANK() OVER (
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank
FROM customer_sales
ORDER BY Sales_Rank;

-- Calculate the sales contribution of the top 10 customers.
WITH customer_sales AS (
    SELECT
        Customer_ID,
        Customer_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Customer_ID, Customer_Name
),
top_10 AS (
    SELECT *
    FROM customer_sales
    ORDER BY Total_Sales DESC
    LIMIT 10
)
SELECT
    ROUND(SUM(Total_Sales), 2) AS Top_10_Customer_Sales,
    ROUND(
        SUM(Total_Sales) /
        (SELECT SUM(Sales) FROM retail) * 100,
        2
    ) AS Top_10_Sales_Percentage
FROM top_10;


/* ================================================================
   8. PRODUCT ANALYSIS
   ================================================================ */

-- Calculate total sales for each product.
SELECT
    Product_ID,
    Product_Name,
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Product_ID, Product_Name, Category
ORDER BY Total_Sales DESC;

-- Top 10 products by total sales.
WITH product_sales AS (
    SELECT
        Product_ID,
        Product_Name,
        Category,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Product_ID, Product_Name, Category
)
SELECT
    Product_ID,
    Product_Name,
    Category,
    ROUND(Total_Sales, 2) AS Total_Sales
FROM product_sales
ORDER BY Total_Sales DESC
LIMIT 10;

-- Find the top 3 products inside every category.
-- ROW_NUMBER creates a separate ranking for each category.
WITH product_sales AS (
    SELECT
        Category,
        Product_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Category, Product_Name
),
ranked_products AS (
    SELECT
        Category,
        Product_Name,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY Total_Sales DESC
        ) AS Rank_In_Category
    FROM product_sales
)
SELECT
    Category,
    Product_Name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Rank_In_Category
FROM ranked_products
WHERE Rank_In_Category <= 3
ORDER BY Category, Rank_In_Category;


/* ================================================================
   9. PRODUCT PERFORMANCE COMPARED WITH AVERAGE
   ================================================================ */

-- First calculate sales for every product.
-- Then compare each product with the average product sales.
WITH product_sales AS (
    SELECT
        Product_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Product_Name
),
average_product_sales AS (
    SELECT
        AVG(Total_Sales) AS Average_Sales
    FROM product_sales
)
SELECT
    p.Product_Name,
    ROUND(p.Total_Sales, 2) AS Total_Sales,
    ROUND(a.Average_Sales, 2) AS Average_Product_Sales
FROM product_sales p
CROSS JOIN average_product_sales a
WHERE p.Total_Sales > a.Average_Sales
ORDER BY p.Total_Sales DESC;


/* ================================================================
   10. TIME ANALYSIS
   ================================================================ */

-- Sales by year.
SELECT
    YEAR(Order_Date) AS Year,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY YEAR(Order_Date)
ORDER BY Year;

-- Sales by year and month.
-- YEAR and MONTH are used together so months from different years
-- are not mixed together.
SELECT
    YEAR(Order_Date) AS Year,
    MONTH(Order_Date) AS Month,
    MONTHNAME(Order_Date) AS Month_Name,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY
    YEAR(Order_Date),
    MONTH(Order_Date),
    MONTHNAME(Order_Date)
ORDER BY Year, Month;


/* ================================================================
   11. YEAR-OVER-YEAR SALES GROWTH
   ================================================================ */

-- LAG gets the previous year's sales.
-- The current year is then compared with the previous year.
WITH yearly_sales AS (
    SELECT
        YEAR(Order_Date) AS Year,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY YEAR(Order_Date)
),
yearly_comparison AS (
    SELECT
        Year,
        Total_Sales,
        LAG(Total_Sales) OVER (
            ORDER BY Year
        ) AS Previous_Year_Sales
    FROM yearly_sales
)
SELECT
    Year,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Previous_Year_Sales, 2) AS Previous_Year_Sales,
    ROUND(
        (Total_Sales - Previous_Year_Sales)
        / NULLIF(Previous_Year_Sales, 0) * 100,
        2
    ) AS YOY_Growth_Percentage
FROM yearly_comparison
ORDER BY Year;


/* ================================================================
   12. MONTH-OVER-MONTH SALES GROWTH
   ================================================================ */

-- LAG gets the previous chronological month.
-- The result is used to calculate month-over-month growth.
WITH monthly_sales AS (
    SELECT
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date)
),
monthly_comparison AS (
    SELECT
        Year,
        Month,
        Total_Sales,
        LAG(Total_Sales) OVER (
            ORDER BY Year, Month
        ) AS Previous_Month_Sales
    FROM monthly_sales
)
SELECT
    Year,
    Month,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(Previous_Month_Sales, 2) AS Previous_Month_Sales,
    ROUND(
        (Total_Sales - Previous_Month_Sales)
        / NULLIF(Previous_Month_Sales, 0) * 100,
        2
    ) AS MOM_Growth_Percentage
FROM monthly_comparison
ORDER BY Year, Month;


/* ================================================================
   13. RUNNING TOTAL
   ================================================================ */

-- Calculate a cumulative sales total within each year.
-- The running total increases month by month.
WITH monthly_sales AS (
    SELECT
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month,
        MONTHNAME(Order_Date) AS Month_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date),
        MONTHNAME(Order_Date)
)
SELECT
    Year,
    Month,
    Month_Name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        SUM(Total_Sales) OVER (
            PARTITION BY Year
            ORDER BY Month
        ),
        2
    ) AS Running_Total
FROM monthly_sales
ORDER BY Year, Month;


/* ================================================================
   14. THREE-MONTH MOVING AVERAGE
   ================================================================ */

-- The window contains the current month and the previous two months.
-- This smooths short-term changes in monthly sales.
WITH monthly_sales AS (
    SELECT
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month,
        MONTHNAME(Order_Date) AS Month_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date),
        MONTHNAME(Order_Date)
)
SELECT
    Year,
    Month,
    Month_Name,
    ROUND(Total_Sales, 2) AS Total_Sales,
    ROUND(
        AVG(Total_Sales) OVER (
            ORDER BY Year, Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Three_Month_Moving_Average
FROM monthly_sales
ORDER BY Year, Month;


/* ================================================================
   15. SALES BY MONTH AND CATEGORY
   ================================================================ */

-- Monthly category sales are calculated first.
-- Then a three-month moving average is calculated separately
-- for each category.
WITH monthly_category_sales AS (
    SELECT
        YEAR(Order_Date) AS Year,
        MONTH(Order_Date) AS Month,
        MONTHNAME(Order_Date) AS Month_Name,
        Category,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date),
        MONTHNAME(Order_Date),
        Category
)
SELECT
    Year,
    Month,
    Month_Name,
    Category,
    ROUND(Total_Sales, 2) AS Monthly_Sales,
    ROUND(
        AVG(Total_Sales) OVER (
            PARTITION BY Category
            ORDER BY Year, Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Three_Month_Average
FROM monthly_category_sales
ORDER BY Category, Year, Month;


/* ================================================================
   16. SHIPPING ANALYSIS
   ================================================================ */

-- Calculate the number of days between ordering and shipping.
SELECT
    Order_ID,
    Order_Date,
    Ship_Date,
    DATEDIFF(Ship_Date, Order_Date) AS Ship_Days
FROM retail
LIMIT 15;

-- Overall shipping statistics.
SELECT
    COUNT(*) AS Total_Rows,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 2) AS Average_Ship_Days,
    MIN(DATEDIFF(Ship_Date, Order_Date)) AS Minimum_Ship_Days,
    MAX(DATEDIFF(Ship_Date, Order_Date)) AS Maximum_Ship_Days
FROM retail;

-- Compare average shipping time across Ship Modes.
SELECT
    Ship_Mode,
    COUNT(*) AS Total_Rows,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 2) AS Average_Ship_Days
FROM retail
GROUP BY Ship_Mode
ORDER BY Average_Ship_Days;

-- Classify each order line based on shipping time.
SELECT
    Order_ID,
    Ship_Mode,
    DATEDIFF(Ship_Date, Order_Date) AS Ship_Days,
    CASE
        WHEN DATEDIFF(Ship_Date, Order_Date) <= 1 THEN 'Fast'
        WHEN DATEDIFF(Ship_Date, Order_Date) <= 3 THEN 'Moderate'
        ELSE 'Slow'
    END AS Shipping_Category
FROM retail;

-- Count records in each shipping-speed category.
WITH shipping_classification AS (
    SELECT
        CASE
            WHEN DATEDIFF(Ship_Date, Order_Date) <= 1 THEN 'Fast'
            WHEN DATEDIFF(Ship_Date, Order_Date) <= 3 THEN 'Moderate'
            ELSE 'Slow'
        END AS Shipping_Category
    FROM retail
)
SELECT
    Shipping_Category,
    COUNT(*) AS Record_Count
FROM shipping_classification
GROUP BY Shipping_Category
ORDER BY Record_Count DESC;


/* ================================================================
   17. SALES VALUE CLASSIFICATION
   ================================================================ */

-- Classify individual sales values into Low, Medium and High.
SELECT
    Order_ID,
    Sales,
    CASE
        WHEN Sales >= 1000 THEN 'High'
        WHEN Sales >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS Sales_Label
FROM retail
ORDER BY Sales DESC;


/* ================================================================
   18. CUSTOMERS WHO PURCHASED TECHNOLOGY
   ================================================================ */

-- Find unique customers who purchased from the Technology category.
SELECT DISTINCT
    Customer_ID,
    Customer_Name
FROM retail
WHERE Customer_ID IN (
    SELECT Customer_ID
    FROM retail
    WHERE Category = 'Technology'
)
ORDER BY Customer_ID;


/* ================================================================
   19. CUSTOMERS ABOVE AVERAGE SALES
   ================================================================ */

-- First calculate sales per customer.
-- Then calculate the average customer sales.
-- Finally return customers above that average.
WITH customer_sales AS (
    SELECT
        Customer_ID,
        Customer_Name,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Customer_ID, Customer_Name
),
average_customer_sales AS (
    SELECT
        AVG(Total_Sales) AS Average_Sales
    FROM customer_sales
)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    ROUND(c.Total_Sales, 2) AS Total_Sales,
    ROUND(a.Average_Sales, 2) AS Average_Customer_Sales
FROM customer_sales c
CROSS JOIN average_customer_sales a
WHERE c.Total_Sales > a.Average_Sales
ORDER BY c.Total_Sales DESC;


/* ================================================================
   20. JOIN ANALYSIS
   ================================================================ */

-- Create a small customer table from the retail data.
-- This demonstrates how a customer dimension can be separated
-- from transaction-level data.
DROP TEMPORARY TABLE IF EXISTS customer_demo;

CREATE TEMPORARY TABLE customer_demo AS
SELECT DISTINCT
    Customer_ID,
    Customer_Name,
    Segment
FROM retail;

-- Create an order-level analysis table.
DROP TEMPORARY TABLE IF EXISTS order_demo;

CREATE TEMPORARY TABLE order_demo AS
SELECT
    Order_ID,
    Customer_ID,
    Sales
FROM retail;

-- INNER JOIN:
-- Returns records where a customer exists in both tables.
SELECT
    c.Customer_ID,
    c.Customer_Name,
    o.Order_ID,
    o.Sales
FROM customer_demo c
INNER JOIN order_demo o
    ON c.Customer_ID = o.Customer_ID
LIMIT 100;

-- LEFT JOIN:
-- Keeps every customer from customer_demo and matches orders
-- where available.
SELECT
    c.Customer_ID,
    c.Customer_Name,
    o.Order_ID,
    o.Sales
FROM customer_demo c
LEFT JOIN order_demo o
    ON c.Customer_ID = o.Customer_ID
LIMIT 100;

-- Aggregate joined data to calculate sales by customer.
SELECT
    c.Customer_ID,
    c.Customer_Name,
    ROUND(SUM(o.Sales), 2) AS Total_Sales
FROM customer_demo c
INNER JOIN order_demo o
    ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY Total_Sales DESC;


/* ================================================================
   21. CROSS JOIN ANALYSIS
   ================================================================ */

-- Create distinct regions and categories.
DROP TEMPORARY TABLE IF EXISTS cross_join_region;
DROP TEMPORARY TABLE IF EXISTS cross_join_category;

CREATE TEMPORARY TABLE cross_join_region AS
SELECT DISTINCT Region
FROM retail;

CREATE TEMPORARY TABLE cross_join_category AS
SELECT DISTINCT Category
FROM retail;

-- CROSS JOIN creates every possible Region x Category combination.
-- With 4 regions and 3 categories, the result has 12 combinations.
SELECT
    r.Region,
    c.Category
FROM cross_join_region r
CROSS JOIN cross_join_category c
ORDER BY r.Region, c.Category;


/* ================================================================
   22. SELF JOIN ANALYSIS
   ================================================================ */

-- Pair customers who belong to the same segment.
-- Customer_ID < Customer_ID prevents duplicate/reversed pairs
-- and prevents a customer from being paired with themselves.
SELECT
    c1.Customer_Name AS Customer_01,
    c2.Customer_Name AS Customer_02,
    c1.Segment
FROM customer_demo c1
INNER JOIN customer_demo c2
    ON c1.Segment = c2.Segment
    AND c1.Customer_ID < c2.Customer_ID
ORDER BY c1.Segment;


/* ================================================================
   23. REGION x CATEGORY SALES OUTPUT
   ================================================================ */

-- Final reporting-style output for regional category analysis.
-- Useful for Power BI or report validation.
SELECT
    Region,
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM retail
GROUP BY Region, Category
ORDER BY Region, Total_Sales DESC;


/* ================================================================
   24. TOP CATEGORY PERFORMANCE BY YEAR
   ================================================================ */

-- Calculate category sales for every year.
WITH yearly_category_sales AS (
    SELECT
        Category,
        YEAR(Order_Date) AS Year,
        SUM(Sales) AS Total_Sales
    FROM retail
    GROUP BY Category, YEAR(Order_Date)
),
ranked_category_sales AS (
    SELECT
        Category,
        Year,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY Total_Sales DESC
        ) AS Rank_In_Category
    FROM yearly_category_sales
)
SELECT
    Category,
    Year,
    ROUND(Total_Sales, 2) AS Total_Sales,
    Rank_In_Category
FROM ranked_category_sales
WHERE Rank_In_Category <= 2
ORDER BY Category, Rank_In_Category;


/* ================================================================
   25. FINAL VALIDATION QUERIES
   ================================================================ */

-- Final KPI check.
-- These values should agree with the project report and Power BI.
SELECT
    ROUND(SUM(Sales), 2) AS Total_Sales,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    COUNT(DISTINCT Product_ID) AS Total_Products,
    ROUND(
        SUM(Sales) / COUNT(DISTINCT Order_ID),
        2
    ) AS AOV,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 2) AS Average_Ship_Days
FROM retail;

-- Final category validation.
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Category
ORDER BY Total_Sales DESC;

-- Final regional validation.
SELECT
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales
FROM retail
GROUP BY Region
ORDER BY Total_Sales DESC;


/*
====================================================================
END OF FINAL SQL ANALYSIS
====================================================================

Recommended execution flow:

DATA CHECK
    |
    v
DATA QUALITY
    |
    v
MAIN KPIs
    |
    +--> CATEGORY
    |
    +--> REGION
    |
    +--> SEGMENT
    |
    +--> CUSTOMER
    |
    +--> PRODUCT
    |
    +--> SHIPPING
    |
    +--> TIME ANALYSIS
              |
              +--> YoY Growth
              +--> MoM Growth
              +--> Running Total
              +--> Moving Average
    |
    v
ADVANCED SQL
    |
    +--> CTEs
    +--> Subqueries
    +--> Window Functions
    +--> JOINs
    +--> CROSS JOIN
    +--> SELF JOIN
    |
    v
FINAL VALIDATION
    |
    v
POWER BI / REPORT
====================================================================
*/

