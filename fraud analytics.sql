CREATE TABLE fraud_transactions_raw (
transaction_id   VARCHAR(20),
customer_id      VARCHAR(20),
transaction_date  DATETIME,
amount            VARCHAR(20),  --text for now, since rows have '$'
merchant_category  VARCHAR (50) NULL,
channel           VARCHAR(20),
country           VARCHAR(20),
card_present       BIT,
account_age_days    INT,
is_fraud            INT
);



select count (*) from [fraud transactions raw];

SELECT name from sys.tables;

DROP TABLE
fraud_transactions_raw;

EXEC sp_rename '[fraud transactions raw]','fraud_transctions_raw';

select * from fraud_transctions_raw;

select Top 20 amount FROM fraud_transctions_raw;--To look at actual amount values

select amount FROM fraud_transctions_raw WHERE amount LIKE '%$%\' --To find rows still showing the  $ symbol

EXEC sp_help fraud_transctions_raw; --check the actual data type of amount now(look for float or money instead of varchar)

--in ssms, F8 toggles or reopen object explorer on and off
--ctrl + r; show/hide results pane
--execute (f5) runs your sql  query

--DATA CLEANING 

SELECT COUNT(*) FROM fraud_transctions_raw WHERE  merchant_category IS NULL; --checks for missing categories

SELECT DISTINCT country FROM fraud_transctions_raw;-- To look for lowercase vs uppercase inconsistencies (e.g,"us", "US")

SELECT COUNT(*) FROM fraud_transctions_raw WHERE account_age_days = -1;--checks for the invalid placeholder values

Select count(*) from fraud_transctions_raw WHERE account_age_days IS NULL;

UPDATE fraud_transctions_raw SET merchant_category = 'Unknown' WHERE merchant_category IS NULL;

SELECT COUNT(*) FROM fraud_transctions_raw WHERE merchant_category = 'Unknown';

SELECT AVG(account_age_days) FROM fraud_transctions_raw WHERE account_age_days IS NOT NULL;--RUN THIS TO CHECK  1525

UPDATE fraud_transctions_raw SET account_age_days = (SELECT AVG (account_age_days) FROM fraud_transctions_raw
WHERE account_age_days IS NOT NULL) WHERE account_age_days IS NULL; 

SELECT COUNT(*) FROM fraud_transctions_raw WHERE account_age_days IS NULL; --SHOULD now return()

SELECT COUNT(*) FROM fraud_transctions_raw;

SELECT is_fraud, COUNT(*) AS total, AVG(CAST(amount AS FLOAT)) AS avg_amount FROM fraud_transctions_raw
GROUP BY is_fraud; -- compares fraud vs non-fraud transaction averages.

SELECT country, COUNT (*) AS fraud_count FROM fraud_transctions_raw WHERE is_fraud =1
GROUP BY country ORDER BY fraud_count DESC; --shows which countries have the most fraud.

SELECT DISTINCT country FROM fraud_transctions_raw WHERE country = LTRIM(RTRIM(country));

SELECT country, LEN(country) AS len_with_spaces, LEN(LTRIM(RTRIM(country))) AS len_trimmed
FROM fraud_transctions_raw
GROUP BY country;

SELECT transaction_id,COUNT(*) FROM fraud_transctions_raw GROUP BY transaction_id HAVING COUNT(*) >1;

--FRAUD PATTERN ANALYSIS
SELECT is_fraud, COUNT(*) As total, AVG(CAST(amount AS FLOAT)) AS avg_amount,
MIN(CAST(amount AS FLOAT)) AS min_amount, MAX(CAST(amount AS FLOAT)) AS max_amount
FROM fraud_transctions_raw GROUP BY is_fraud; --gives a fuller comparison of fraud vs non_fraud amount(not just average)

SELECT channel, COUNT(*) AS total, SUM(CASE WHEN is_fraud =1 THEN 1 ELSE 0 END) AS fraud_count,
ROUND(100.0 * SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END)/ COUNT(*), 2) AS fraud_rate_pct FROM 
fraud_transctions_raw GROUP BY channel ORDER BY fraud_rate_pct DESC;
--YOUR FIRST REAL FRAUD RATE Broken down by channel

SELECT country, COUNT(*) AS total, SUM(CASE WHEN is_fraud =1 THEN 1 ELSE 0 END) AS fraud_count,
ROUND(100.0 * SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END)/ COUNT(*), 2) AS fraud_rate_pct FROM 
fraud_transctions_raw GROUP BY country ORDER BY fraud_rate_pct DESC;
--YOUR FIRST REAL FRAUD RATE Broken down by country

SELECT 
 CASE
    WHEN CAST(amount AS FLOAT) < 50 THEN 'Under $50'
    WHEN CAST(amount AS FLOAT) < 200 THEN 'Under $200'
    WHEN CAST(amount AS FLOAT) < 500 THEN 'Under $500'
    ELSE 'Over $500'
    END AS amount_tier,
    COUNT(*) AS total,
    SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(100.0 * SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
    FROM fraud_transctions_raw
    GROUP BY
     CASE
     WHEN CAST(amount AS FLOAT) < 50 THEN 'Under $50'
    WHEN CAST(amount AS FLOAT) < 200 THEN 'Under $200'
    WHEN CAST(amount AS FLOAT) < 500 THEN 'Under $500'
    ELSE 'Over $500'
    END
    ORDER BY fraud_rate_pct DESC;

    SELECT 
    DATEPART(HOUR, transaction_date) AS hour_of_day,
    COUNT(*) AS total,
    SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(100.0 * SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
    FROM fraud_transctions_raw
    GROUP BY DATEPART(HOUR, transaction_date)
    ORDER BY hour_of_day;

    SELECT
    merchant_category,
    COUNT(*) AS total,
    SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(100.0 * SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
    FROM fraud_transctions_raw
    GROUP BY merchant_category
    ORDER BY fraud_rate_pct DESC;
