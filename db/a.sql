DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @tableList TABLE (TableName NVARCHAR(255), SchemaName NVARCHAR(50), FullTableName NVARCHAR(255));
DECLARE @startDate DATE = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
DECLARE @endDate DATE = CAST(GETDATE() AS DATE);

-- Step 1: Find tables with Load_Dt or LOAD_DT and additionalComments in the EDR schema
INSERT INTO @tableList (TableName, SchemaName, FullTableName)
SELECT 
    t.TABLE_NAME,
    t.TABLE_SCHEMA,
    QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) AS FullTableName
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c1 
    ON t.TABLE_SCHEMA = c1.TABLE_SCHEMA 
    AND t.TABLE_NAME = c1.TABLE_NAME
INNER JOIN INFORMATION_SCHEMA.COLUMNS c2 
    ON t.TABLE_SCHEMA = c2.TABLE_SCHEMA 
    AND t.TABLE_NAME = c2.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'EDR'
    AND UPPER(c1.COLUMN_NAME) IN ('LOAD_DT', 'LOAD_DT') -- Case-insensitive check
    AND UPPER(c2.COLUMN_NAME) = 'ADDITIONALCOMMENTS';   -- Case-insensitive check

-- Debug: Print the tables found
PRINT 'Tables found with required columns:';
DECLARE @debugTable NVARCHAR(255), @debugSchema NVARCHAR(255);
DECLARE debug_cursor CURSOR FOR 
    SELECT TableName, SchemaName FROM @tableList;
OPEN debug_cursor;
FETCH NEXT FROM debug_cursor INTO @debugTable, @debugSchema;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @debugSchema + '.' + @debugTable;
    FETCH NEXT FROM debug_cursor INTO @debugTable, @debugSchema;
END;
CLOSE debug_cursor;
DEALLOCATE debug_cursor;

-- Step 2: Check if any tables were found before proceeding
IF EXISTS (SELECT 1 FROM @tableList)
BEGIN
    -- Use a cursor to iterate over the filtered table list
    DECLARE @tableCursor CURSOR;
    SET @tableCursor = CURSOR FOR 
        SELECT FullTableName, TableName FROM @tableList;

    DECLARE @currentTable NVARCHAR(255);
    DECLARE @currentTableName NVARCHAR(255);

    OPEN @tableCursor;
    FETCH NEXT FROM @tableCursor INTO @currentTable, @currentTableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = @sql + '
        SELECT CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) AS [Date],
               COUNT([additionalComments]) AS Volume,
               ''' + @currentTableName + ''' AS TableName
        FROM ' + @currentTable + '
        WHERE [additionalComments] IS NOT NULL
        AND CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + '''
        GROUP BY CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE)';

        -- Only add UNION ALL if there are more tables to process
        FETCH NEXT FROM @tableCursor INTO @currentTable, @currentTableName;
        IF @@FETCH_STATUS = 0
            SET @sql = @sql + '
        UNION ALL';
    END;

    CLOSE @tableCursor;
    DEALLOCATE @tableCursor;

    -- Step 3: Execute the dynamic SQL
    PRINT 'Generated SQL:';
    PRINT @sql;
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END
ELSE
BEGIN
    PRINT 'No tables found with both Load_Dt/LOAD_DT and additionalComments columns.';
END;
​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​