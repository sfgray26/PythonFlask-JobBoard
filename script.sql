DECLARE @sql NVARCHAR(MAX) = '';

-- Add each table and column combination from the list
SET @sql = @sql + '
SELECT CAST([TimestampColumn] AS DATE) AS [Date],
       COUNT([additionalComments]) AS Volume,
       ''EDR.LoanDetail'' AS TableName
FROM [EDR].[LoanDetail]
WHERE [additionalComments] IS NOT NULL
GROUP BY CAST([TimestampColumn] AS DATE)

UNION ALL

SELECT CAST([TimestampColumn] AS DATE) AS [Date],
       COUNT([lienPositionComments]) AS Volume,
       ''EDR.LoanDetail'' AS TableName
FROM [EDR].[LoanDetail]
WHERE [lienPositionComments] IS NOT NULL
GROUP BY CAST([TimestampColumn] AS DATE)

UNION ALL

SELECT CAST([TimestampColumn] AS DATE) AS [Date],
       COUNT([transactionComments]) AS Volume,
       ''EDR.LoanDetail_EDR_14Dec2024'' AS TableName
FROM [EDR].[LoanDetail_EDR_14Dec2024]
WHERE [transactionComments] IS NOT NULL
GROUP BY CAST([TimestampColumn] AS DATE)

UNION ALL

SELECT CAST([TimestampColumn] AS DATE) AS [Date],
       COUNT([comments]) AS Volume,
       ''EDR.LocationsDetail'' AS TableName
FROM [EDR].[LocationsDetail]
WHERE [comments] IS NOT NULL
GROUP BY CAST([TimestampColumn] AS DATE)

-- Add more cases for other tables and columns from the list...
';

-- ✅ Remove trailing UNION ALL
IF LEN(@sql) > 0
    SET @sql = LEFT(@sql, LEN(@sql) - 10); 

-- ✅ Execute if not empty
IF LEN(@sql) > 0 
BEGIN
    PRINT @sql;
    EXEC sp_executesql @sql;
END
ELSE 
BEGIN
    PRINT 'No valid tables or columns found.';
END;