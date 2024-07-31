/* Search DB tables for two columns in same table
Create Date:        2022-03-10, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Search a database schema for tables containing two field names of interest.
Description:        Returns results table containing names of tables which contain both fields 
					matching the search terms. 
Call by:            Ad-hoc during SQL script development.
Database:  			Any valid DB.
Used By:            Data Analyst
Parameter(s):       @field1 (varchar) - contains search term to be looked for in field names.
					@field2 (varchar) - contains 2nd search term to be looked for in field names.
Usage:              Data on individual fields is optional and can be removed by commenting out
					the relevant line in the query.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31          Tom Ling			Portfolio version.
2022-03-10          Tom Ling			Initial script completed.
***************************************************************************************************/


/* Specify database to use */
USE [databasename]
GO

/* Declare and set two search term variables */
DECLARE @field1 VARCHAR(250)
DECLARE @field2 VARCHAR(250)
SET @field1 = 'size'
SET @field2 = 'mountpath'

/* Find tables containing field of interest */
SELECT DISTINCT
	result_tables.*
	/* Comment out the line below if you don't need to see the data for individual search terms (column names). */
	,subquery_columns.*

FROM (
	/* (1) Subquery to get tables with both search terms in the column names */
	SELECT DISTINCT
		--is_c.[TABLE_CATALOG] AS [Table Catalog]
		--,is_c.[TABLE_SCHEMA] AS [Table Schema]
		results_term1.[TABLE_NAME] AS [Table Name]
		,COUNT(results_term1.[TABLE_NAME]) AS [Count of search terms]
	FROM 
		(/* Query to get tables containing search term 1 */
		SELECT * FROM INFORMATION_SCHEMA.COLUMNS is_c
		WHERE
			is_c.COLUMN_NAME like '%' + @field1 + '%' 
		) results_term1
		
		/* Inner join filters out table names that only contain one of the search terms. */
		INNER JOIN
		
		(/* Query to get tables containing search term 2 */
		SELECT * FROM INFORMATION_SCHEMA.COLUMNS is_c
		WHERE
			is_c.COLUMN_NAME like '%' + @field2 + '%' 
		) results_term2 ON results_term1.[TABLE_NAME] = results_term2.[TABLE_NAME]
	GROUP BY
		results_term1.[TABLE_CATALOG]
		,results_term1.[TABLE_SCHEMA]
		,results_term1.[TABLE_NAME]
	HAVING
		 /* Keep only tables where the search terms appeared at least twice. */
		 COUNT(results_term1.[TABLE_NAME]) >= 2) result_tables

	LEFT JOIN (
	/* (2) Subquery to display the original column names and related info */
	SELECT 
		is_c.* 
	FROM 
		INFORMATION_SCHEMA.COLUMNS is_c
	WHERE 
		is_c.COLUMN_NAME like '%' + @field1 + '%' 
		OR is_c.COLUMN_NAME like '%' + @field2 + '%' 
	) subquery_columns ON subquery_columns.[TABLE_NAME] = result_tables.[Table Name]

ORDER BY
	result_tables.[Table Name]
	--,subquery_columns.[ORDINAL_POSITION]