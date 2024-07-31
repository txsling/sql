/* Recursive CTE for folder hierarchy
Create Date:        2020-07-29, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Test query for returning a SolarWinds group hierarchy.
Description:        Returns the SolarWinds group hierarchy shown in the Orion interface.
Call by:            e.g. Audit Excel file
Database:  			e.g. [databasename]
Used By:            Operations Department
Parameter(s):       @param1 - description and usage
                    @param2 - description and usage
Usage:              N/A.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2020-07-29          Tom Ling			Initial script completed.
***************************************************************************************************/


WITH ParentFolderTable ([ContainerID], [Member], [TopLevelContainer])
AS (
	/* Query to get all top level folders (called groups in SW Console, containers in DB) */
	SELECT DISTINCT
		NULL AS [ContainerID]
		,CAST(c.[ContainerID] as varchar(255)) AS [Member]
		,c.[ContainerID] AS [TopLevelContainer]
	FROM [SolarWindsOrion].[dbo].[ContainerMemberDefinitions] c
	LEFT JOIN 
	(SELECT 
		c.[ContainerID]
		,CAST(SUBSTRING(c.[Name],CHARINDEX('ContainerID=',c.[Name])+LEN('ContainerID='),9999) as varchar(255)) AS [Member]
	FROM [SolarWindsOrion].[dbo].[ContainerMemberDefinitions] c
	WHERE c.[Name] LIKE '%ContainerID=%' AND c.[Entity] = 'Orion.Groups') c2
	ON c.[ContainerID] = c2.[Member]
	WHERE c2.[ContainerID] IS NULL

UNION ALL
    /* Recursive query to get folders belonging to a top level folder */
	SELECT
		c.[ContainerID] AS [ContainerID]
		,CAST(SUBSTRING(c.[Name],CHARINDEX('ContainerID=',c.[Name])+LEN('ContainerID='),9999) as varchar(255)) AS [Member]
		,pft.[TopLevelContainer] as [TopLevelContainer]
	FROM [SolarWindsOrion].[dbo].[ContainerMemberDefinitions] c
	INNER JOIN ParentFolderTable pft
	ON c.[ContainerID] = pft.[Member]
	WHERE c.[Name] LIKE '%ContainerID=%' AND c.[Entity] = 'Orion.Groups'
)
SELECT pft.*
	,con2.[Name] as [MemberContainerName]
	,con.[Name] as [TopLevelContainerName]
FROM ParentFolderTable pft
INNER JOIN [SolarWindsOrion].[dbo].[Containers] con
ON pft.[TopLevelContainer] = con.[ContainerID]
INNER JOIN [SolarWindsOrion].[dbo].[Containers] con2
ON pft.[Member] = con2.[ContainerID]