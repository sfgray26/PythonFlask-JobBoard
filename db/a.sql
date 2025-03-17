DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @tableList TABLE (
    TableName NVARCHAR(255), 
    SchemaName NVARCHAR(50), 
    FullTableName NVARCHAR(255),
    CommentColumn NVARCHAR(255)
);
DECLARE @startDate DATE = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));
DECLARE @endDate DATE = CAST(GETDATE() AS DATE);

-- Step 1: Find tables with Load_Dt or LOAD_DT and any comment column in the EDR schema
INSERT INTO @tableList (TableName, SchemaName, FullTableName, CommentColumn)
SELECT 
    t.TABLE_NAME,
    t.TABLE_SCHEMA,
    QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) AS FullTableName,
    c2.COLUMN_NAME AS CommentColumn
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c1 
    ON t.TABLE_SCHEMA = c1.TABLE_SCHEMA 
    AND t.TABLE_NAME = c1.TABLE_NAME
INNER JOIN INFORMATION_SCHEMA.COLUMNS c2 
    ON t.TABLE_SCHEMA = c2.TABLE_SCHEMA 
    AND t.TABLE_NAME = c2.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'EDR'
    AND UPPER(c1.COLUMN_NAME) IN ('LOAD_DT', 'LOAD_DT') -- Case-insensitive check
    AND UPPER(c2.COLUMN_NAME) IN (
        'ADDITIONALCOMMENTS',
        'LIENPOSITIONCOMMENTS',
        'TRANSACTIONCOMMENTS',
        'INTAPPSERVICECOMMENTS',
        'INTAPPADDITIONALCOMMENTS',
        'ISBUSINESSOUTSIDERESIDENCECOMMENTS',
        'AGADDITIONALPROPCOMMENTS',
        'INTAPPADDITIONALPROPCOMMENTS',
        'STRUCTUREFLOODZONECOMMENTS',
        'PROP_COMMENTS'
    );

-- Debug: Print the tables found with their comment columns
PRINT 'Tables found with required columns:';
DECLARE @debugTable NVARCHAR(255), @debugSchema NVARCHAR(255), @debugCommentColumn NVARCHAR(255);
DECLARE debug_cursor CURSOR FOR 
    SELECT TableName, SchemaName, CommentColumn FROM @tableList;
OPEN debug_cursor;
FETCH NEXT FROM debug_cursor INTO @debugTable, @debugSchema, @debugCommentColumn;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @debugSchema + '.' + @debugTable + ' (Comment Column: ' + @debugCommentColumn + ')';
    FETCH NEXT FROM debug_cursor INTO @debugTable, @debugSchema, @debugCommentColumn;
END;
CLOSE debug_cursor;
DEALLOCATE debug_cursor;

-- Step 2: Check if any tables were found before proceeding
IF EXISTS (SELECT 1 FROM @tableList)
BEGIN
    -- Use a cursor to iterate over the filtered table list
    DECLARE @tableCursor CURSOR;
    SET @tableCursor = CURSOR FOR 
        SELECT FullTableName, TableName, CommentColumn FROM @tableList;

    DECLARE @currentTable NVARCHAR(255);
    DECLARE @currentTableName NVARCHAR(255);
    DECLARE @currentCommentColumn NVARCHAR(255);

    OPEN @tableCursor;
    FETCH NEXT FROM @tableCursor INTO @currentTable, @currentTableName, @currentCommentColumn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = @sql + '
        SELECT t.[Date],
               COUNT(t.@CommentColumnParam) AS Volume,
               COUNT(DISTINCT CASE WHEN t.@CommentColumnParam IS NOT NULL THEN t.[Date] END) AS DistinctVolume,
               ''' + @currentTableName + ''' AS TableName,
               (SELECT TOP 1 r.CommentValue 
                FROM (SELECT @CommentColumnParam AS CommentValue,
                             ROW_NUMBER() OVER (PARTITION BY CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) ORDER BY (SELECT NULL)) AS RowNum
                      FROM ' + @currentTable + '
                      WHERE @CommentColumnParam IS NOT NULL
                      AND CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + ''') r
                WHERE r.RowNum = 1 
                AND CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) = t.[Date]) AS SampleComment
        FROM (SELECT CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) AS [Date],
                     @CommentColumnParam
              FROM ' + @currentTable + '
              WHERE @CommentColumnParam IS NOT NULL
              AND CAST(COALESCE([Load_Dt], [LOAD_DT]) AS DATE) BETWEEN ''' + CONVERT(VARCHAR(10), @startDate, 120) + ''' AND ''' + CONVERT(VARCHAR(10), @endDate, 120) + ''') t
        GROUP BY t.[Date]';

        FETCH NEXT FROM @tableCursor INTO @currentTable, @currentTableName, @currentCommentColumn;
        IF @@FETCH_STATUS = 0
            SET @sql = @sql + '
        UNION ALL';
    END;

    CLOSE @tableCursor;
    DEALLOCATE @tableCursor;

    -- Define the parameter for sp_executesql
    DECLARE @paramDefinition NVARCHAR(500) = N'@CommentColumnParam NVARCHAR(255)';
    PRINT 'Generated SQL:';
    PRINT @sql;
    BEGIN TRY
        EXEC sp_executesql @sql, @paramDefinition, @CommentColumnParam = @currentCommentColumn;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;
END
ELSE
BEGIN
    PRINT 'No tables found with both Load_Dt/LOAD_DT and a recognized comment column.';
END;
​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​