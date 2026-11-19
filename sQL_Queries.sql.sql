
CREATE TABLE year_2009_2010 (
    invoice VARCHAR(50),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INT,
    invoice_date VARCHAR(50),
    price NUMERIC(10, 2),
    customer_id VARCHAR(50),
    country VARCHAR(100)
);

CREATE TABLE year_2010_2011 (
    invoice VARCHAR(50),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INT,
    invoice_date VARCHAR(50),
    price NUMERIC(10, 2),
    customer_id VARCHAR(50),
    country VARCHAR(100)
);
SELECT COUNT(*) AS rows_2009_2010 FROM year_2009_2010;
SELECT COUNT(*) AS rows_2010_2011 FROM year_2010_2011;



CREATE TABLE retail_combined AS
SELECT 
    invoice,
    stock_code,
    description,
    quantity,
    CASE 
        WHEN invoice_date ~ '^\d{4}-\d{2}-\d{2}' THEN TO_TIMESTAMP(invoice_date, 'YYYY-MM-DD HH24:MI:SS')
        WHEN invoice_date ~ '^\d{2}-\d{2}-\d{4}' THEN TO_TIMESTAMP(invoice_date, 'DD-MM-YYYY HH24:MI:SS')
        WHEN invoice_date ~ '^\d{2}/\d{2}/\d{4}' THEN TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI:SS')
        ELSE NULL 
    END AS invoice_date,
    NULLIF(TRIM(price::TEXT), '')::NUMERIC(10, 2) AS price,
    customer_id,
    country,
    '2009-2010' AS source_sheet
FROM year_2009_2010

UNION ALL

SELECT 
    invoice,
    stock_code,
    description,
    quantity,
    CASE 
        WHEN invoice_date ~ '^\d{4}-\d{2}-\d{2}' THEN TO_TIMESTAMP(invoice_date, 'YYYY-MM-DD HH24:MI:SS')
        WHEN invoice_date ~ '^\d{2}-\d{2}-\d{4}' THEN TO_TIMESTAMP(invoice_date, 'DD-MM-YYYY HH24:MI:SS')
        WHEN invoice_date ~ '^\d{2}/\d{2}/\d{4}' THEN TO_TIMESTAMP(invoice_date, 'DD/MM/YYYY HH24:MI:SS')
        ELSE NULL 
    END AS invoice_date,
    NULLIF(TRIM(price::TEXT), '')::NUMERIC(10, 2) AS price,
    customer_id,
    country,
    '2010-2011' AS source_sheet
FROM year_2010_2011;

SELECT * FROM retail_combined LIMIT 10;

-- CHECK 1 - MISSING CUSTOMER 
SELECT COUNT(*) AS missing_customerid
FROM retail_combined 
WHERE customer_id IS NULL OR TRIM(customer_id) = '';

-- CHECK 2 - NEGATIVE OR ZERO QUANTITY 
SELECT COUNT(*) AS negative_qty
FROM retail_combined 
WHERE quantity <= 0;

-- CHECK 3 - MISSING DESCRIPTION 
SELECT COUNT(*) AS missing_description
FROM retail_combined 
WHERE description IS NULL OR TRIM(description) = '';

-- CHECK 4 - EXACT DUPLICATE ROWS 
SELECT invoice, stock_code, description, quantity, invoice_date, price, customer_id, country,
       COUNT(*) AS exact_dupe_count
FROM retail_combined
GROUP BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
HAVING COUNT(*) > 1;

-- DEDUPLICATE AND PRODUCE THE FINAL CLEANED TABLE
CREATE TABLE retail_cleaned AS
WITH Deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY invoice, stock_code, description, quantity, invoice_date, price, customer_id, country
        ) AS row_num
    FROM retail_combined
)
SELECT 
    invoice, 
    stock_code, 
    description, 
    quantity, 
    invoice_date, 
    price, 
    customer_id, 
    country, 
    source_sheet
FROM Deduped
WHERE row_num = 1;



