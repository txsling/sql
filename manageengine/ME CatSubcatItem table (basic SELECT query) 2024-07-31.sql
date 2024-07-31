/* ManageEngine CatSubcatItem table
Create Date:        2020-10-28, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Return category, subcategory and item names and definitions.
Description:        Return category, subcategory and item names and definitions (excluding deleted 
					categories). 
Call by:            N/A
Database:  			[manageengine]
Used By:            Data Analyst
Parameter(s):       N/A
Usage:              Run script ad-hoc.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2020-10-28          Tom Ling			Initial script completed.
***************************************************************************************************/


USE [manageengine]
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
ORDER BY
	[Category]
	,[Subcategory]
	,[Item]