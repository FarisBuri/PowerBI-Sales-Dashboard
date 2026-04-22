-- Sales Data Analysis Project using SQL
-- Includes data modeling, transformations, and business insights


-- Create Customers table (stores customer information)
create table Customers (
    Customer_ID NVARCHAR(100) Primary Key,  -- Unique customer ID
    Customer_Name NVARCHAR(100),            -- Customer full name
    City NVARCHAR(100),
    State NVARCHAR(100),
    Pincode INT,
    Email_ID NVARCHAR(100),
    Phone_Number NVARCHAR(20)
);

-- Create Products table (stores product details)
Create table Products(
    Product_ID NVARCHAR(100) Primary Key,   -- Unique product ID
    Product_Name NVARCHAR(100),
    Product_Line NVARCHAR(100),             -- Category or product line
    Price Decimal(10,2)                     -- Selling price
);

-- Create Promotion table (stores discount and promotion data)
Create Table Promotion (
    Promotion_ID NVARCHAR(100) Primary Key,
    Promotion_Name NVARCHAR(100),
    Ad_Type NVARCHAR(100),                  -- Type of advertisement
    Coupon_Code NVARCHAR(100),
    Price_Reduction_Type NVARCHAR(100)      -- Discount format (e.g. 10%, BOGO)
);

-- Create Sales table (fact table for transactions)
create table Sales(
    Sale_ID INT IDENTITY(1,1) PRIMARY KEY,  -- Auto increment ID
    Date_time Date,
    Customer_ID NVARCHAR(100),
    Promotion_ID NVARCHAR(100),
    Product_ID NVARCHAR(100),
    Unit_Sold INT,
    Price_Per_Unit Decimal,                 -- Will be filled from Products table
    Total_Sales Decimal(10,2),
    Discount_Percentage INT,
    Discount_Value Decimal(10,2),
    Net_Sales Decimal(10,2),

    -- Foreign keys for data integrity
    CONSTRAINT FK_Sales_Customers
    FOREIGN KEY (Customer_ID)
    REFERENCES Customers(Customer_ID),

    Constraint FK_Sales_Promotion
    Foreign Key (Promotion_ID)
    References Promotion(Promotion_ID),

    Constraint FK_Sales_Products
    Foreign Key (Product_ID)
    References Products(Product_ID)
);

-- Update price per unit from Products table
Update s
SET s.Price_Per_Unit = p.Price
From Sales s
INNER JOIN Products p
ON s.Product_ID = p.Product_ID;

-- Calculate total sales = price * quantity
Update s
SET s.Total_Sales = s.Price_Per_Unit * s.Unit_Sold
From Sales s;

-- Clean and standardize discount values in Promotion table
UPDATE Promotion
SET Price_Reduction_Type = 
CASE 
    WHEN Price_Reduction_Type LIKE '%Buy 1 Get 1%' THEN '50' -- Treat BOGO as 50%
    WHEN Price_Reduction_Type LIKE '%\%%' ESCAPE '\' 
    THEN REPLACE(REPLACE(Price_Reduction_Type, '% off', ''), '%', '')
    ELSE Price_Reduction_Type
END;

-- Apply discount percentage to Sales table
update s
set s.Discount_Percentage = p.Price_Reduction_Type
From Sales s 
Inner JOIN Promotion p
ON s.Promotion_ID = p.Promotion_ID;

-- Replace NULL discounts with 0
update sales
SET Discount_Percentage = 0
WHERE Discount_Percentage IS Null;

-- Calculate discount value
Update Sales
SET Discount_Value = ( Total_Sales / 100 ) * Discount_Percentage;

-- Calculate net sales after discount
UPDATE Sales
SET Net_Sales = Total_Sales - Discount_Value;

-- Add product cost column
alter table Products 
ADD Cost Decimal (10,2);

-- Assume cost = 70% of price
UPDATE Products
SET Cost = Price * 0.7;

-- Add profit column to Sales
alter table Sales
ADD Profit Decimal(10,2);

-- (Optional improvement: you can calculate Profit = Net_Sales - Cost * Unit_Sold)

------------------------------------------------------------
-- 🔍 Analysis Queries
------------------------------------------------------------

-- Top 5 products by total profit
SELECT TOP 5 
    p.Product_Name,
    SUM(s.Profit) AS Total_Profit
FROM Sales s
INNER JOIN Products p 
    ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Total_Profit DESC;

-- Validation: number of customers in March 2023
SELECT 
    DATENAME(MONTH, s.Date_time) AS Month_Name, 
    COUNT(s.Customer_ID) AS Total_Customers
From Sales s 
INNER JOIN Customers c 
    ON c.Customer_ID = s.Customer_ID 
WHERE MONTH(s.Date_time) = 3 
  AND YEAR(s.Date_time) = 2023 
GROUP BY DATENAME(MONTH, s.Date_time);