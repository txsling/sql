/* SW Reports and Schedules List
Create Date:        2021-10-12, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Returns information from SolarWinds DB on the SW reports and schedules. 
Description:        Returns information from SolarWinds DB on Reports, Schedules, schedule 
					frequency and actions defined for each schedule. Each combination of
					report x schedule x frequency x action returns a separate row, unless 
					otherwise specified.
Call by:            N/A
Database:  			[SolarWinds]
Used By:            Data Analyst
Parameter(s):       N/A
Usage:              N/A
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2023-03-03          Tom Ling			Made changes to return schedule name more easily.
2022-05-06          Tom Ling			Add Account used to run schedule to set of fields returned.
2022-02-10          Tom Ling			Added Type and Description to results. Added commented out
										lines to return distinct reports without schedule info.
2021-10-12          Tom Ling			Initial script completed.
***************************************************************************************************/

SELECT DISTINCT
	*
	/* Comment out the line above and uncomment the lines below if you only want one report per line */
	--result.[Report ID],
	--result.[Schedule Name]
	--,result.[Report Name]
	--,result.[Report URL]
	--,result.[Description]
	--,result.[Type]
FROM 
	(SELECT 
		repdef.[ReportID] AS [Report ID]
		,repdef.[Title] AS [Report Name]
		,CONCAT('https://reportingserver.com/Orion/Report.aspx?ReportID=',repdef.[ReportID]) AS [Report URL]
		--,[SubTitle]
		,repdef.[Description]
		,repdef.[Type]
		-- ,[Category]
		--,[Owner]
		--,repjob.[ReportJobID] /* Schedule ID */
		,ISNULL(repjob.[Name],'') AS [Schedule Name] /* Empty string indicates report is not scheduled */
		--,ISNULL(repjob.[Description],'') AS [Schedule Description]
		,ISNULL(freq.[DisplayName],'') AS [Frequency]
		,ISNULL(act.[Title],'') AS [Action]
		,CASE
			WHEN act.[Enabled] = 1 THEN 'On'
			WHEN act.[Enabled] = 0 THEN 'Off'
			ELSE ''	
		END AS [Action Status]
		,CASE 
			WHEN repjob.[Enabled] = 1 THEN 'On'
			WHEN repjob.[Enabled] = 0 THEN 'Off'
			ELSE ''	
		END AS [Schedule Status]
		,repjob.[LastRun] AS [Schedule Last Run]
		,repjob.[AccountID] AS [Account used to run schedule]
	FROM
		/* Report definitions table */
		[SolarWindsOrion].[dbo].[ReportDefinitions] repdef
		/* Map reports to schedules (jobs) */
		LEFT JOIN [SolarWindsOrion].[dbo].[ReportJobDefinitions] repjobdef ON repdef.[ReportID] = repjobdef.[ReportID]
		LEFT JOIN [SolarWindsOrion].[dbo].[ReportJobs] repjob ON repjobdef.[ReportJobID] = repjob.[ReportJobID]
		/* Map schedules to frequencies */
		LEFT JOIN [SolarWindsOrion].[dbo].[ReportSchedules] repsch ON repjob.[ReportJobID] = repsch.[ReportJobID]
		LEFT JOIN [SolarWindsOrion].[dbo].[Frequencies] freq ON repsch.[FrequencyID] = freq.[FrequencyID]
		/* Map schedules to actions */
		LEFT JOIN [SolarWindsOrion].[dbo].[ActionsAssignments] actass ON repjob.[ReportJobID] = actass.[ParentID] AND actass.[EnvironmentType] = 'Reporting'
		LEFT JOIN [SolarWindsOrion].[dbo].[Actions] act ON actass.[ActionID] = act.[ActionID]
	) result
--WHERE
	--result.[Report Name] LIKE '%Internet Utili_ation%'
	--result.[Account used to run schedule] != 'admin'
	--result.[Schedule Name] != ''
ORDER BY
	result.[Schedule Name]
	,result.[Report Name]