/* SW Nodes added in last year
Create Date:        2021-11-11, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Gets list of nodes that were added to SolarWinds in the last year.
Description:        Looks at the Events (audit) table to find Node Added events and then matches
					these to Nodes in the Nodes table and then to VMs in the Virtual Machines 
					table. (This approach doesn't pick up VMs that aren't also monitored as nodes.)
					Nodes corresponding to access points and switches are filtered out of the 
					results but this may not be 100% effective. Also, event times and VM created 
					times appear to be unreliable. Need to understand SW better to determine 
					whether this approach is worthwhile. 
Call by:            N/A
Database:  			[SolarWinds]
Used By:            Data Analyst
Parameter(s):       @startDate - start of time range to search
                    @endDate - end of time range to search
Usage:              See above.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2021-11-11          Tom Ling			Initial script completed.
***************************************************************************************************/

/* Time range */
DECLARE @startDate datetime
SET @startDate = DATEADD(year,-1,CURRENT_TIMESTAMP)
DECLARE @endDate datetime
SET @endDate = CURRENT_TIMESTAMP

--SELECT @startDate AS [Start Date]
--SELECT @endDate AS [End Date]

/* Result query */
SELECT 
	events.[EventID]
	,events.[EventTime]
	--,events.[EventType]
	--,events.[NetworkNode]
	,nd.[Caption] AS [Node Name]
	,vm.[Name] AS [VM Name]
	,vm.[DateCreated] AS [VM Created Date]
	--,events.[NetObjectID]
	,events.[Message]
	--,nd.[MachineType]
	--,wap.[Name]
FROM 
	/* Events (audit) table */
	[SolarWindsOrion].[dbo].[Events] events
	/* Event types table */
	LEFT JOIN [SolarWindsOrion].[dbo].[EventTypes] evtype ON events.[EventType] = evtype.[EventType]
	/* Nodes table */
	LEFT JOIN [SolarWindsOrion].[dbo].[NodesData] nd ON events.[NetworkNode] = nd.[NodeID]
	/* Virtual Machines table */
	LEFT JOIN [SolarWindsOrion].[dbo].[VirtualMachines] vm ON nd.[NodeID] = vm.[NodeID]
	/* Filter out access points */
	LEFT JOIN [SolarWindsOrion].[dbo].[Wireless_AccessPoints] wap ON nd.[Caption] = wap.[Name]
WHERE 
	events.[EventTime] BETWEEN @startDate AND @endDate
	AND vm.[DateCreated] BETWEEN @startDate AND @endDate
	AND (evtype.[Name] = 'Node Added') /* Only nodes added */
	AND wap.[Name] IS NULL /* Exclude Access Points */
	--AND (nd.[Caption] LIKE '%VM Prefix%' 
		--OR nd.[Caption] LIKE '%VM Prefix 2%') /* Specific node names */
	AND nd.[MachineType] NOT LIKE '%Cisco%' /* Exclude switches */
	--AND [Message] LIKE '%VM Name%'