-- Create a table variable to hold the data
DECLARE @tables TABLE (
    TABLE_SCHEMA VARCHAR(255),
    TABLE_NAME VARCHAR(255),
    COLUMN_NAME VARCHAR(255),
    DATA_TYPE VARCHAR(255)
);

-- Import the data from the CSV file
BULK INSERT @tables
FROM 'C:\Your\Path\To\Your\Data.csv' -- Replace with your CSV file path
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMATFILE = 'C:\Your\Path\To\Your\format.fmt' -- Replace with your format file path
);

-- Dynamic SQL to generate the queries
DECLARE @sql NVARCHAR(MAX);
DECLARE @unionSql NVARCHAR(MAX);

SET @sql = '';
SET @unionSql = '';

-- Loop through the tables and generate the queries
SELECT @sql = @sql +
    'SELECT ''' + t.TABLE_SCHEMA + '.' + t.TABLE_NAME + ''' AS TableName, ' +
    'CAST(COALESCE(c.DateColumn, ''2024-01-01'') AS DATE) AS Date, ' + --Replace with the real date column.
    'COUNT(' + QUOTENAME(t.COLUMN_NAME) + ') AS Volume ' +
    'FROM ' + QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) + ' ' +
    'WHERE ' + QUOTENAME(t.COLUMN_NAME) + ' IS NOT NULL ' +
    'GROUP BY CAST(COALESCE(c.DateColumn, ''2024-01-01'') AS DATE) ' + --Replace with the real date column.
    'UNION ALL '
FROM @tables t
CROSS APPLY (SELECT CASE t.TABLE_NAME
                        WHEN 'LoanDetail' THEN 'LoanDate'
                        WHEN 'LoanDetail_EDR' THEN 'LoanDate'
                        WHEN 'LoanDetail_EDR_14Dec2024' THEN 'LoanDate'
                        WHEN 'LoanDetail_HIST' THEN 'LoanDate'
                        WHEN 'LoanDetail_HIST_14Dec2024' THEN 'LoanDate'
                        WHEN 'LocationLoanInfo_EDR_14Dec' THEN 'LoanDate'
                        WHEN 'LocationLoanInfo_HIST_14Dec' THEN 'LoanDate'
                        WHEN 'Locations' THEN 'CreateDate'
                        WHEN 'Locations_EDR' THEN 'CreateDate'
                        WHEN 'Locations_HIST' THEN 'CreateDate'
                        WHEN 'LocationsDetail' THEN 'CreateDate'
                        WHEN 'LocationsDetail_EDR' THEN 'CreateDate'
                        WHEN 'LocationsDetail_EDR_14Dec20' THEN 'CreateDate'
                        WHEN 'LocationsDetail_EDR_14Dec20' THEN 'CreateDate'
                        WHEN 'LocationsDetail_HIST' THEN 'CreateDate'
                        WHEN 'LocationsDetail_HIST_14Dec20' THEN 'CreateDate'
                    END AS DateColumn) c;

-- Remove the trailing 'UNION ALL'
IF LEN(@sql) > 0
BEGIN
    SET @unionSql = LEFT(@sql, LEN(@sql) - 11);
END

-- Execute the dynamic SQL
IF LEN(@unionSql) > 0
BEGIN
    PRINT @unionSql;
    EXEC sp_executesql @unionSql;
END
ELSE
BEGIN
    PRINT 'No tables or columns found to search';
END;
