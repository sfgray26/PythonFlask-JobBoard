-- Create a temporary table to hold the data
CREATE TABLE #tables (
    TABLE_SCHEMA VARCHAR(255),
    TABLE_NAME VARCHAR(255),
    COLUMN_NAME VARCHAR(255),
    DATA_TYPE VARCHAR(255)
);

-- Import the data from the CSV file
BULK INSERT #tables
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
    'CAST(COALESCE(dc.COLUMN_NAME, ''2024-01-01'') AS DATE) AS Date, ' +
    'COUNT(' + QUOTENAME(t.COLUMN_NAME) + ') AS Volume ' +
    'FROM ' + QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) + ' ' +
    'WHERE ' + QUOTENAME(t.COLUMN_NAME) + ' IS NOT NULL ' +
    'GROUP BY CAST(COALESCE(dc.COLUMN_NAME, ''2024-01-01'') AS DATE) ' +
    'UNION ALL '
FROM #tables t
OUTER APPLY (
    SELECT TOP 1 COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = t.TABLE_SCHEMA
      AND TABLE_NAME = t.TABLE_NAME
      AND (COLUMN_NAME LIKE '%date%' OR COLUMN_NAME LIKE '%time%')
      AND DATA_TYPE IN ('date', 'datetime', 'smalldatetime', 'timestamp')
    ORDER BY COLUMN_NAME --optional, but will make result consistent.
) dc;

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

-- Drop the temporary table
DROP TABLE #tables;
