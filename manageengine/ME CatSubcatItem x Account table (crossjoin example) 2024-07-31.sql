/* ManageEngine CatSubcatItem table x Account
Create Date:        2021-09-28, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Return category, subcategory and item names and definitions table, for accounts
					specified in a temp table.
Description:        Return category, subcategory and item names and definitions (excluding deleted 
					categories) multiplied by accounts specified in a temp table. 
Call by:            N/A
Database:  			[manageengine]
Used By:            Data Analyst
Parameter(s):       @clientTable - temporary table used to store client names for cross join.
Usage:              Run script ad-hoc.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2021-09-28          Tom Ling			Initial script completed.
***************************************************************************************************/

USE [manageengine]

/* Use this temp table to populate the client names in the results. Set 'include' value to 1 to include in results. */
DECLARE @clientTable TABLE (Name varchar(100), include INT);
INSERT INTO @clientTable values 
	('Client1', 1)
	,('Client2', 1)

SELECT 
	* 
FROM
	(/* Generate list of client names */
	SELECT 
		[Name] AS [Client]
	FROM 
		@clientTable
	WHERE 
		[include] = 1
	) clients
CROSS JOIN
	(/* Generate Cat-Subcat-item table from ManageEngine DB */
	SELECT
		catdef.[CATEGORYNAME] AS [Category]
		,subcatdef.[NAME] AS [Subcategory]
		,itemdef.[NAME] AS [Item]
	FROM 
		[ItemDefinition] itemdef
		LEFT JOIN [SubCategoryDefinition] subcatdef ON itemdef.[SUBCATEGORYID] = subcatdef.[SUBCATEGORYID]
		LEFT JOIN [CategoryDefinition] catdef ON subcatdef.[CATEGORYID] = catdef.[CATEGORYID]
	WHERE 
		itemdef.[ISDELETED] = 0
		AND subcatdef.[ISDELETED] = 0
		AND catdef.[ISDELETED] = 0
	) csitable
ORDER BY
	clients.[Client]
	,csitable.[Category]
	,csitable.[Subcategory]
	,csitable.[Item]