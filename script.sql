-- Check if #date_columns exists and drop it if it does
IF OBJECT_ID('tempdb..#date_columns') IS NOT NULL
    DROP TABLE #date_columns;

-- Check if #tables exists and drop it if it does
IF OBJECT_ID('tempdb..#tables') IS NOT NULL
    DROP TABLE #tables;

-- Check if #results exists and drop it if it does
IF OBJECT_ID('tempdb..#results') IS NOT NULL
    DROP TABLE #results;

-- Create a temporary table to hold the data
CREATE TABLE #tables (
    TABLE_SCHEMA VARCHAR(255),
    TABLE_NAME VARCHAR(255),
    COLUMN_NAME VARCHAR(255),
    DATA_TYPE VARCHAR(255)
);

-- Insert the data manually (replace with your data)
INSERT INTO #tables (TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE) VALUES
    ('EDR', 'LoanDetail', 'additionalComments', 'nvarchar'),
    ('EDR', 'LoanDetail', 'lienPositionComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR', 'additionalComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR', 'lienPositionComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR_14Dec2024', 'transactionComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR_14Dec2024', 'additionalComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR_14Dec2024', 'lienPositionComments', 'varchar'),
    ('EDR', 'LoanDetail_EDR_14Dec2024', 'intAppServiceComments', 'varchar'),
    ('EDR', 'LoanDetail_HIST', 'additionalComments', 'nvarchar'),
    ('EDR', 'LoanDetail_HIST', 'lienPositionComments', 'varchar'),
    ('EDR', 'LoanDetail_HIST_14Dec2024', 'transactionComments', 'varchar'),
    ('EDR', 'LoanDetail_HIST_14Dec2024', 'additionalComments', 'nvarchar'),
    ('EDR', 'LoanDetail_HIST_14Dec2024', 'lienPositionComments', 'varchar'),
    ('EDR', 'LocationLoanInfo_EDR_14Dec', 'loanTypeComments', 'varchar'),
    ('EDR', 'LocationLoanInfo_HIST_14Dec', 'loanTypeComments', 'varchar'),
    ('EDR', 'Locations', 'comments', 'text'),
    ('EDR', 'Locations_EDR', 'comments', 'varchar'),
    ('EDR', 'Locations_HIST', 'comments', 'varchar'),
    ('EDR', 'LocationsDetail', 'comments', 'text'),
    ('EDR', 'LocationsDetail', 'transactionComments', 'varchar'),
    ('EDR', 'LocationsDetail', 'isBusinessOutsideResidenceComm', 'varchar'),
    ('EDR', 'LocationsDetail', 'agriAdditionalPropComments', 'nvarchar'),
    ('EDR', 'LocationsDetail', 'lihtcAdditionalComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'comments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'transactionComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'isBusinessOutsideResidenceComm', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'agriAdditionalPropComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'agricultureComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR', 'lihtcAdditionalComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'comments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'structureFloodZoneComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'transactionComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'isBusinessOutsideResidenceComm', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'agriAdditionalPropComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'agricultureComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'lihtcAdditionalComments', 'varchar'),
    ('EDR', 'LocationsDetail_EDR_14Dec20', 'propertyComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST', 'comments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST', 'transactionComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST', 'isBusinessOutsideResidenceComm', 'varchar'),
    ('EDR', 'LocationsDetail_HIST', 'agriAdditionalPropComments', 'nvarchar'),
    ('EDR', 'LocationsDetail_HIST', 'lihtcAdditionalComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'comments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'structureFloodZoneComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'transactionComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'isBusinessOutsideResidenceComm', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'agriAdditionalPropComments', 'nvarchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'agricultureComments', 'varchar'),
    ('EDR', 'LocationsDetail_HIST_14Dec20', 'lihtcAdditionalComments', 'varchar');

-- Create a function to get the date column name
CREATE FUNCTION GetDateColumn(@TableName VARCHAR(255))
RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @DateColumn VARCHAR(255);

    SET @DateColumn = CASE @TableName
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
        WHEN 'LocationsDetail_HIST' THEN 'CreateDate'
        WHEN 'LocationsDetail_HIST_14Dec20' THEN 'CreateDate'
        ELSE NULL
    END;

    RETURN @DateColumn;
END;

-- Dynamic SQL to generate the queries
DECLARE @sql NVARCHAR(MAX);
DECLARE @unionSql NVARCHAR(MAX);

SET @sql = '';
SET @unionSql = '';

-- Loop through the tables and generate the queries
SELECT @sql = @sql +
    'SELECT ''' + t.TABLE_SCHEMA + '.' + t.TABLE_NAME + ''' AS TableName, ' +
    'CAST(COALESCE(dbo.GetDateColumn(''' + t.TABLE_NAME + '''), ''2024-01-01'') AS DATE) AS Date, ' +
    'COUNT(' + QUOTENAME(t.COLUMN_NAME) + ') AS Volume ' +
    'FROM ' + QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) + ' ' +
    'WHERE ' +
