/* Search DB tables for a specific column
Create Date:        2021-05-11, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Search a database schema for tables containing 1 or 2 field names of interest.
Description:        Returns results table containing names of tables which containing fields 
					matching the search terms.
Call by:            Ad-hoc during SQL script development.
Database:  			Any valid DB.
Used By:            Data Analyst
Parameter(s):       @field1 (varchar) - contains 1st search term to be looked for in field names.
					@field2 (varchar) - contains 2nd search term to be looked for in field names.
Usage:              Doesn't require table names to contain both search terms, just one or the other.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2022-03-10          Tom Ling			Script supports a second search term. Added distinct table
										names as optional result query.
2021-08-20          Tom Ling			Documentation block added. Improved syntax/layout.
2021-05-11          Tom Ling			Initial script completed.
***************************************************************************************************/


/* Specify database to use */
USE [databasename]
GO

/* Declare a search term variable */
DECLARE @field1 VARCHAR(250)
DECLARE @field2 VARCHAR(250)

/* Set the first search term here */
SET @field1 = 'media'
SET @field2 = @field1

/* If using a second search term, uncomment the line below to set it here */
--SET @field2 = 'jobid'


/* Find tables containing field of interest */
SELECT 
	is_c.* 
FROM INFORMATION_SCHEMA.COLUMNS is_c
WHERE
	is_c.[COLUMN_NAME] like '%' + @field1 + '%' 
	OR is_c.[COLUMN_NAME] like '%' + @field2 + '%' 
ORDER BY
	is_c.[TABLE_NAME]


/* If you only need the table names and not much else, uncomment and use the version below. */
--SELECT DISTINCT
--	is_c.[TABLE_CATALOG]
--	,is_c.[TABLE_SCHEMA]
--	,is_c.[TABLE_NAME]
--FROM INFORMATION_SCHEMA.COLUMNS is_c
--WHERE
--	is_c.[COLUMN_NAME] like '%' + @field1 + '%' 
--	OR is_c.[COLUMN_NAME] like '%' + @field2 + '%' 
--ORDER BY
--	is_c.[TABLE_NAME]