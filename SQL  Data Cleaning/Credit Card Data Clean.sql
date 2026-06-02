SELECT COUNT(*) 
FROM creditcard_data;

-- STEP 1 : Create a working copy of the raw table
CREATE TABLE creditcard_clean AS
SELECT * FROM creditcard_data;

SELECT COUNT(*) 
FROM creditcard_clean;


-- STEP 2 : Check for duplicate rows

 
-- a) See if any Client_Num appears more than once
SELECT Client_Num, COUNT(*) AS how_many_times
FROM creditcard_clean
GROUP BY Client_Num
HAVING COUNT(*) > 1;

-- b) If duplicates exist, remove them.
DELETE FROM creditcard_clean
WHERE rowid NOT IN (
    SELECT MIN(rowid)          -- keep the row with the smallest rowid
    FROM creditcard_clean
    GROUP BY Client_Num        -- for each unique Client_Num
);


-- STEP 4 : Check for NULL / missing values

SELECT
    SUM(CASE WHEN Client_Num            IS NULL THEN 1 ELSE 0 END) AS missing_Client_Num,
    SUM(CASE WHEN Card_Category         IS NULL THEN 1 ELSE 0 END) AS missing_Card_Category,
    SUM(CASE WHEN Annual_Fees           IS NULL THEN 1 ELSE 0 END) AS missing_Annual_Fees,
    SUM(CASE WHEN Activation_30_Days    IS NULL THEN 1 ELSE 0 END) AS missing_Activation_30_Days,
    SUM(CASE WHEN Customer_Acq_Cost     IS NULL THEN 1 ELSE 0 END) AS missing_Customer_Acq_Cost,
    SUM(CASE WHEN Week_Start_Date       IS NULL THEN 1 ELSE 0 END) AS missing_Week_Start_Date,
    SUM(CASE WHEN Week_Num              IS NULL THEN 1 ELSE 0 END) AS missing_Week_Num,
    SUM(CASE WHEN Qtr                   IS NULL THEN 1 ELSE 0 END) AS missing_Qtr,
    SUM(CASE WHEN current_year          IS NULL THEN 1 ELSE 0 END) AS missing_current_year,
    SUM(CASE WHEN Credit_Limit          IS NULL THEN 1 ELSE 0 END) AS missing_Credit_Limit,
    SUM(CASE WHEN Total_Revolving_Bal   IS NULL THEN 1 ELSE 0 END) AS missing_Total_Revolving_Bal,
    SUM(CASE WHEN Total_Trans_Amt       IS NULL THEN 1 ELSE 0 END) AS missing_Total_Trans_Amt,
    SUM(CASE WHEN Total_Trans_Vol       IS NULL THEN 1 ELSE 0 END) AS missing_Total_Trans_Vol,
    SUM(CASE WHEN Avg_Utilization_Ratio IS NULL THEN 1 ELSE 0 END) AS missing_Avg_Utilization_Ratio,
    SUM(CASE WHEN Use_Chip              IS NULL THEN 1 ELSE 0 END) AS missing_Use_Chip,
    SUM(CASE WHEN Exp_Type              IS NULL THEN 1 ELSE 0 END) AS missing_Exp_Type,
    SUM(CASE WHEN Interest_Earned       IS NULL THEN 1 ELSE 0 END) AS missing_Interest_Earned,
    SUM(CASE WHEN Delinquent_Acc        IS NULL THEN 1 ELSE 0 END) AS missing_Delinquent_Acc
FROM creditcard_clean;


-- STEP 5 : Fix date format  (DD-MM-YYYY  →  YYYY-MM-DD)

UPDATE creditcard_clean
SET Week_Start_Date =
    SUBSTR(Week_Start_Date, 7, 4) || '-' ||   -- year
    SUBSTR(Week_Start_Date, 4, 2) || '-' ||   -- month
    SUBSTR(Week_Start_Date, 1, 2)             -- day
WHERE Week_Start_Date LIKE '__-__-____';

-- Verifying the change looks correct:
SELECT Week_Start_Date
FROM creditcard_clean
WHERE ROWNUM <= 5;


-- STEP 6 : Trim extra spaces from text columns
 
UPDATE creditcard_clean SET Use_Chip     = TRIM(Use_Chip);
UPDATE creditcard_clean SET Exp_Type     = TRIM(Exp_Type);
UPDATE creditcard_clean SET Card_Category= TRIM(Card_Category);
UPDATE creditcard_clean SET Qtr          = TRIM(Qtr);
UPDATE creditcard_clean SET Week_Num     = TRIM(Week_Num);
 
-- Verify no more trailing spaces in Use_Chip:
SELECT DISTINCT Use_Chip FROM creditcard_clean;

-- STEP 7 : Standardise text case

UPDATE creditcard_clean
SET Card_Category = UPPER(SUBSTR(Card_Category, 1, 1)) ||
                    LOWER(SUBSTR(Card_Category, 2));
 
UPDATE creditcard_clean
SET Use_Chip = UPPER(SUBSTR(Use_Chip, 1, 1)) ||
               LOWER(SUBSTR(Use_Chip, 2));
 
UPDATE creditcard_clean
SET Exp_Type = UPPER(SUBSTR(Exp_Type, 1, 1)) ||
               LOWER(SUBSTR(Exp_Type, 2));
               
-- STEP 8 : Check for unexpected / invalid category values
 
-- Card types should be: Blue, Silver, Gold, Platinum
SELECT DISTINCT Card_Category FROM creditcard_clean ORDER BY Card_Category;
 
-- Payment method should be: Chip, Swipe, Online
SELECT DISTINCT Use_Chip FROM creditcard_clean ORDER BY Use_Chip;
 
-- Expense type should be: Travel, Entertainment, Bills, Grocery, Fuel, Food
SELECT DISTINCT Exp_Type FROM creditcard_clean ORDER BY Exp_Type;
 
-- Quarter should be: Q1, Q2, Q3, Q4
SELECT DISTINCT Qtr FROM creditcard_clean ORDER BY Qtr;


-- STEP 9 : Check for negative values in numeric columns

SELECT COUNT(*) AS negative_Annual_Fees
FROM creditcard_clean WHERE Annual_Fees < 0;
 
SELECT COUNT(*) AS negative_Credit_Limit
FROM creditcard_clean WHERE Credit_Limit < 0;
 
SELECT COUNT(*) AS negative_Total_Trans_Amt
FROM creditcard_clean WHERE Total_Trans_Amt < 0;
 
SELECT COUNT(*) AS negative_Interest_Earned
FROM creditcard_clean WHERE Interest_Earned < 0;
 
SELECT COUNT(*) AS negative_Customer_Acq_Cost
FROM creditcard_clean WHERE Customer_Acq_Cost < 0;

-- 
-- STEP 10 : Check Avg_Utilization_Ratio is between 0 and 1
 
SELECT COUNT(*) AS invalid_utilization
FROM creditcard_clean
WHERE Avg_Utilization_Ratio < 0
   OR Avg_Utilization_Ratio > 1

-- STEP 11 : Check Activation_30_Days and Delinquent_Acc
 
SELECT COUNT(*) AS invalid_Activation_30_Days
FROM creditcard_clean
WHERE Activation_30_Days NOT IN (0, 1);
 
SELECT COUNT(*) AS invalid_Delinquent_Acc
FROM creditcard_clean
WHERE Delinquent_Acc NOT IN (0, 1);

-- STEP 12 : Check the year column makes sense
 
SELECT DISTINCT current_year FROM creditcard_clean ORDER BY current_year;

-- STEP 13 : Extract week number as integer from Week_Num
 
ALTER TABLE creditcard_clean
ADD Week_Num_Int NUMBER;
UPDATE creditcard_clean
SET Week_Num_Int = TO_NUMBER(REPLACE(Week_Num, 'Week-', ''));
-- Verify it looks right:
SELECT Week_Num, Week_Num_Int
FROM creditcard_clean
WHERE ROWNUM <= 5;
 
 

-- STEP 14 : Final check — preview the cleaned data
 
SELECT *
FROM creditcard_clean
WHERE ROWNUM <= 10;
 
-- Row count should match original (unless duplicates were removed):
SELECT COUNT(*) AS total_rows
FROM creditcard_clean;
 