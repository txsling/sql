/* ME Open Tickets Last Month
Create Date:        2022-08-26, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Provides monthly report on open tickets.
Description:        Returns data on tickets and Change Requests in ManageEngine, 
					where the ticket is NOT Resolved or Closed / the Change has NOT reached 
					Closed stage and Completed Status and is NOT Cancelled / the Sales ticket
					is not Completed or Cancelled.
					All tickets are included regardless of whether time has been spent or not.
					By default the script returns open tickets and changes in ManageEngine, 
					excluding Sales tickets, which were created in the time range.
					(Projects aren't included in this script.) 
					Time Spent is either in Range (meaning, worklogs within the date range of the 
					query) or in Total (meaning, all worklogs regardless of date range). 
Call by:            Embedded in other reporting but can be run manually. 
Database:  			[manageengine] (ManageEngine database)
Used By:            Operations Department
Parameter(s):       @startDate - start of time range for tickets. 
                    @endDate - end of time range for tickets. 
					@openTickets - set to 1 to filter tickets by Request Status != Closed, 
					default is 0.
					@openChanges - set to 1 to filter Changes by Change Status = Closed, 
					default is 0.
					@salesTickets - whether sales tickets and other tickets are included.
					@createdWithinRange - whether the ticket must have been created on or 
					after the startDate and strictly before the endDate.
Usage:              NOTE: Time Spent may be only that within the time range, or in total. 
					Within the time range means some time spent will not be captured by this method. 
					e.g. if a ticket was closed on 1st of the month, all the time spent on it the 
					month before (or after) will not be included!
					By default (running the script as is without changing any parameters) the script
					will return (1) a single row table showing the date range and settings and (2) a 
					result table showing the total worklog time against each request and change in 
					ManageEngine. 
					Set relevant parameters directly in the script if results other than the default
					are required. See notes within the script comments.
					Time Category null values are replaced with 'In Hours'. This is because 
					technicians often omit to select 'In Hours' when filling in worklogs. 
					Time Spent (hours) is a float value, which may result in small rounding 
					errors. Time Spent (minutes) has exact integer values.
					Project Weighting field is [servicedesk].[dbo].[WorkOrder_Fields] field, field
					name [UDF_CHAR2]. This field contains a semicolon-separated list of values
					corresponding to those that are checked in the ManageEngine request or incident
					page. This script only looks at whether the field contains 'Yes' anywhere in it.
					With default settings the script takes <2s to run. 
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2022-08-30			Tom Ling			Exclude tickets in Sales Order or Sales Quote groups.
2022-08-26          Tom Ling			Initial script completed.
***************************************************************************************************/


/* Tells SSMS to use the ManageEngine DB */
--USE [manageengine]
--GO


/* Sets the value of @startDate to the first day of last month 
and sets the value of @endDate to the first day of this month. */
/* These values are checked in the WHERE clause. Records on and after the startdate 
and strictly before the end date are returned. */
DECLARE @startDate DATETIME
SET @startDate = 
	DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP)-1, 0)		/* Last month's tickets */
	--DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0)		/* This month's tickets */
	--CONVERT(datetime, '2020-01-01')								/* A specific start date */

DECLARE @endDate DATETIME
SET @endDate = 
	--DATEADD(year, 100, @startDate)								/* 100 years' worth of tickets (for all records) */
	--DATEADD(year, 1, @startDate)									/* One year's worth of tickets */
	DATEADD(month, 1, @startDate)									/* One month's worth of tickets, counting from startDate */
	--DATEADD(day, 7, @startDate)									/* One week's worth of tickets */
	--CONVERT(datetime, '2120-07-01')								/* A specific end date */

/* Determine whether to look at Open (those that are NOT Closed/Completed) tickets and changes only, or all tickets and changes. */
DECLARE @openTickets tinyint
SET @openTickets = 
	1			/* 1 = Yes, 0 = No */
	--0
DECLARE @openChanges tinyint
SET @openChanges = 
	1			/* 1 = Yes, 0 = No */
	--0

/* Determine whether to include Sales/Other tickets (i.e. tickets with NULL as REQUESTTYPEID) */
DECLARE @salesTickets tinyint
SET @salesTickets = 
	--1			/* 1 = Include, 0 = Exclude */
	0

/* Ticket was created within time range filter */
DECLARE @createdWithinRange tinyint
SET @createdWithinRange = 
	1			/* 1 = Yes, 0 = No */
	--0

/* This separate query returns the date values and other settings you've chosen, 
so you can check they are correct. */
SELECT 
	CONCAT(LEFT(DATENAME(dw,@startDate),3), ' ', @startDate, ' to ', LEFT(DATENAME(dw,@endDate),3), ' ', @endDate) AS [Time filter]
	,CASE @openTickets
		WHEN 1 THEN 'Open tickets only'
		ELSE 'All tickets'
		END AS [Ticket filter]
	,CASE @openChanges
		WHEN 1 THEN 'Open changes only'
		ELSE 'All changes'
		END AS [Changes filter]
	,CASE @salesTickets
		WHEN 1 THEN 'Include Sales/Other tickets'
		ELSE 'Exclude Sales/Other Tickets'
		END AS [Sales tickets filter]
	,CASE @createdWithinRange
		WHEN 1 THEN 'Only tickets created in time range'
		ELSE 'All tickets'
		END AS [Created Time filter]

/* Main result - all requests and changes which are NOT resolved, closed 
or [Change Stage = Close and Change Status = Completed] in the specified time range, 
along with the time spent on associated worklogs during that time range */

/* Subquery to get all requests and changes and associated data */
SELECT 
	req_change_list_final.* 
	--req_change_list_final.[Request ID]
	--,req_change_list_final.[Subject]
	--,req_change_list_final.[Requestor]
	--,req_change_list_final.[Technician]
	--,req_change_list_final.[Created Time]
	--,req_change_list_final.[Request Status]

	--,timespent_final.[Request Type]
	,ISNULL(timespent_filtered_final.[Time Spent in Range (minutes)],0) AS [Time Spent in Range (minutes)]
	,ISNULL(timespent_filtered_final.[Time Spent in Range (minutes)]*1.0/60,0) AS [Time Spent in Range (hours)]
	,ISNULL(timespent_notfiltered_final.[Time Spent in Total (minutes)],0) AS [Time Spent in Total (minutes)]
	,ISNULL(timespent_notfiltered_final.[Time Spent in Total (minutes)]*1.0/60,0) AS [Time Spent in Total (hours)]
FROM 
	(/* Filtered list of requests and changes */
	SELECT 
		req_change_list.* 
	FROM 
		(/* (1) List of requests */
		SELECT DISTINCT
			CAST(wo.[WORKORDERID] as varchar(8)) AS [Request ID]
			,[ad].[ORG_NAME] AS [Account]
			,ISNULL([qd].[QUEUENAME],'') AS [Group]
			,[wo].[TITLE] AS [Subject]
			,[aau].[FIRST_NAME] AS [Requestor]
			/* Use Assigned To field  as Technician name */
			,ISNULL(aaau_owner.[FIRST_NAME],'') AS [Technician]
			,ISNULL([rtdef].[NAME], 'Sales/Other') AS [Request Type]
			,ISNULL([pdef].[PRIORITYNAME], '') AS [Priority] /* This is the ticket Priority */
			/* Dates are stored as Unix epoch values in milliseconds since 1970-01-01. Commented lines are previous attempts to implement time zone offset. */
			/* This field is the datetime the ticket itself was created */
			,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [wo].[CREATEDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Created Time] /* Converted to UK time zone */
			/* This field is the datetime the ticket status was set to resolved */
			,CASE
				WHEN [wo].[RESOLVEDTIME] = 0 THEN NULL
				ELSE CONVERT(datetime,DATEADD(s, CONVERT(bigint, [wo].[RESOLVEDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0)
				END AS [Resolved Time] /* Tickets aren't closed until manually reviewed by Operations */
			/* Statuses in ME are prefixed with a number, this has to be removed */
			,SUBSTRING([std].[STATUSNAME], CHARINDEX(' ',[std].[STATUSNAME])+1, 99) AS [Request Status]
			/* SLA Response Status and Resolution Status */
			,CASE wos.[IS_FR_OVERDUE] 
				WHEN 1 THEN 'Overdue'
				ELSE ''
				END AS [SLA Response Status] 
			,CASE wos.[ISOVERDUE] 
				WHEN 1 THEN 'Overdue'
				ELSE ''
				END AS [SLA Resolution Status] 
			,ISNULL([catdef].[CATEGORYNAME],'') AS [Category]
			,ISNULL([scd].[NAME],'') AS [Subcategory]
			,ISNULL([icd].[NAME],'') AS [Item]
			/* By default the WorkOrder table only shows the primary CI associated with a request. */
			--,ISNULL([ci].[CINAME],'') AS [Asset Name]
			/* Instead we use this to concatenate all assets associated with a ticket in case there are multiple assets. */
			,ISNULL(
				STUFF(
					(SELECT '; ' + [ci].[CINAME]
					FROM [WorkOrderToCI] [wotoci]
					LEFT JOIN [CI] [ci]	ON [wotoci].[CIID]=[ci].[CIID] 
					INNER JOIN [WorkOrder] [wo2] ON [wo2].[WORKORDERID]=[wotoci].[WORKORDERID]
					WHERE [wo].[WORKORDERID] = [wo2].[WORKORDERID]
					FOR XML PATH (''))
					, 1, 2, '')
				,'') AS [Asset Name]
		FROM 
			/* Requests table */
			[WorkOrder] wo
			/* Requester info */
			LEFT JOIN [SDUser] sdu ON wo.[REQUESTERID] = sdu.[USERID] 
			LEFT JOIN [AaaUser] aau ON sdu.[USERID] = aau.[USER_ID] 
			/* Group info */
			LEFT JOIN [WorkOrder_Queue] [woq] ON [wo].[WORKORDERID]=[woq].[WORKORDERID] 
			LEFT JOIN [QueueDefinition] [qd] ON [woq].[QUEUEID]=[qd].[QUEUEID] 
			/* CI (asset) Names */
			LEFT JOIN [CI] [ci] ON [wo].[CIID]=[ci].[CIID] 
			/* Mapping requests to multiple assets if they are present */
			LEFT JOIN [WorkOrderToCI] [wotoci] ON [wo].[WORKORDERID]=[wotoci].[CIID]
			/* Category, subcategory, item info */
			LEFT JOIN [WorkOrderStates] [wos] ON [wo].[WORKORDERID]=[wos].[WORKORDERID] 
			LEFT JOIN [SubCategoryDefinition] [scd] ON [wos].[SUBCATEGORYID]=[scd].[SUBCATEGORYID] 
			LEFT JOIN [ItemDefinition] [icd] ON [wos].[ITEMID]=[icd].[ITEMID] 
			/* SLA Response Status and Resolution Status is captured in [WorkOrderStates] */
			/* Technician (OwnerID) is captured in [WorkOrderStates] but need to map to name */
			LEFT JOIN [SDUser] sdu_owner ON wos.[OWNERID] = sdu_owner.[USERID]
			LEFT JOIN [AaaUser] aaau_owner ON sdu_owner.[USERID] = aaau_owner.[USER_ID] 
			/* Request type */
			LEFT JOIN [RequestTypeDefinition] [rtdef] ON [wos].[REQUESTTYPEID]=[rtdef].[REQUESTTYPEID] 
			/* Category names */
			LEFT JOIN [CategoryDefinition] [catdef] ON [wos].[CATEGORYID]=[catdef].[CATEGORYID] 
			/* Ticket priority */
			LEFT JOIN [PriorityDefinition] [pdef] ON [wos].[PRIORITYID]=[pdef].[PRIORITYID] 
			/* Ticket status */
			LEFT JOIN [StatusDefinition] [std] ON [wos].[STATUSID]=[std].[STATUSID] 
			/* Match tickets to sites and then sites to accounts */
			LEFT JOIN [AccountSiteMapping] [asm] ON [wo].[SITEID] = [asm].[SITEID]
			LEFT JOIN [AccountDefinition] [ad] ON [asm].[ACCOUNTID] = [ad].[ORG_ID]
			/* Custom fields */
			LEFT JOIN [WorkOrder_Fields] wof ON wo.[WORKORDERID] = wof.[WORKORDERID]
			/* Project Weighting (custom multi field) */
			LEFT JOIN [WorkOrder_Multi_Fields] [womf] ON [wo].[WORKORDERID]=[womf].[WORKORDERID]
			/* Join WorkOrderHistory table to display only tickets closed within the closure time period */
			LEFT JOIN [WorkOrderHistory] [wohist] ON [wo].[WORKORDERID]=[wohist].[WORKORDERID]

		
		UNION ALL


		/* (2) List of Changes */
		SELECT DISTINCT
			CAST(CONCAT('C',cd.[CHANGEID]) as varchar(8)) AS [Request ID]
			,[ad].[ORG_NAME] AS [Account]
			,ISNULL([qd].[QUEUENAME],'') AS [Group]
			,[cd].[TITLE] AS [Subject]
			,[aau].[FIRST_NAME] AS [Requestor]
			/* Use Change Owner field  as Technician name */
			,ISNULL(aau_changeowner.[FIRST_NAME],'') AS [Technician]
			,'Change' AS [Request Type]
			,ISNULL([pdef].[PRIORITYNAME],'') AS [Priority] /* This is the ticket Priority */
			/* Dates are stored as Unix epoch values in milliseconds since 1970-01-01. Commented lines are previous attempts to implement time zone offset. */
			/* This field is the datetime the ticket itself was created */
			,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [cd].[CREATEDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Created Time] /* Converted to UK time zone */
			/* This field is the datetime the ticket status was set to resolved */
			,CASE
				WHEN [cd].[COMPLETEDTIME] = 0 THEN NULL
				ELSE CONVERT(datetime,DATEADD(s, CONVERT(bigint, [cd].[COMPLETEDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0)
				END AS [Resolved Time] /* Actually completed time, but keeping the same field heading as the requests script */
			,CONCAT(ISNULL([chstagedef].[NAME],''), ': ', ISNULL([chstatdef].[STATUSNAME],'')) AS [Request Status]
			/* SLA Response Status and Resolution Status is N/A */
			,'' AS [SLA Response Status] 
			,'' AS [SLA Resolution Status] 
			,ISNULL([catdef].[CATEGORYNAME],'') AS [Category]
			,ISNULL([scd].[NAME],'') AS [Subcategory]
			,ISNULL([icd].[NAME],'') AS [Item]
			/* By default the WorkOrder table only shows the primary CI associated with a request. */
			--,ISNULL([ci].[CINAME],'') AS [Asset Name]
			/* Instead we use this to concatenate all assets associated with a ticket in case there are multiple assets. */
			,ISNULL(
				STUFF(
					(SELECT '; ' + [ci].[CINAME]
					FROM [ChangeToCI] [chtoci]
					LEFT JOIN [CI] [ci]
					ON [chtoci].[CIID]=[ci].[CIID] 
					INNER JOIN [ChangeDetails] [cd2]
					ON [cd2].[CHANGEID]=[chtoci].[CHANGEID]
					WHERE [cd].[CHANGEID] = [cd2].[CHANGEID]
					FOR XML PATH (''))
					, 1, 2, '')
				,'') AS [Asset Name]
			
		FROM 
			/* Change information and title */
			[ChangeDetails] cd
			/* Map changes to worklogs */
			LEFT JOIN [ChangeToCharge] cc ON cc.[CHANGEID] = cd.[CHANGEID]
			LEFT JOIN [ChargesTable] ct ON cc.[CHARGEID] = ct.[CHARGEID] 
			/* Requester info */
			LEFT JOIN [SDUser] sdu ON cd.[INITIATORID] = sdu.[USERID] 
			LEFT JOIN [AaaUser] aau ON sdu.[USERID] = aau.[USER_ID] 
			/* ChangeOwner (Technician) info */
			LEFT JOIN [SDUser] sdu_changeowner ON cd.[TECHNICIANID] = sdu_changeowner.[USERID] 
			LEFT JOIN [AaaUser] aau_changeowner ON sdu_changeowner.[USERID] = aau_changeowner.[USER_ID] 
			/* Group info */
			LEFT JOIN [QueueDefinition] [qd] ON [cd].[GROUPID]=[qd].[QUEUEID] 
			/* Mapping requests to multiple assets if they are present */
			LEFT JOIN [ChangeToCI] [chtoci] ON [cd].[CHANGEID]=[chtoci].[CHANGEID]
			/* CI (asset) Names */
			LEFT JOIN [CI] [ci] ON [chtoci].[CIID]=[ci].[CIID] 
			/* Category, subcategory, item info */
			LEFT JOIN [SubCategoryDefinition] [scd] ON [cd].[SUBCATEGORYID]=[scd].[SUBCATEGORYID] 
			LEFT JOIN [ItemDefinition] [icd] ON [cd].[ITEMID]=[icd].[ITEMID] 
			/* SLA Response Status and Resolution Status is N/A */
			/* Category names */
			LEFT JOIN [CategoryDefinition] [catdef] ON [cd].[CATEGORYID]=[catdef].[CATEGORYID] 
			/* Ticket priority */
			LEFT JOIN [PriorityDefinition] [pdef] ON [cd].[PRIORITYID]=[pdef].[PRIORITYID] 
			/* Change stage */
			LEFT JOIN [Change_StageDefinition] chstagedef ON [cd].[WFSTAGEID] = chstagedef.[WFSTAGEID] 
			/* Change status */
			LEFT JOIN [Change_StatusDefinition] chstatdef ON [cd].[WFSTATUSID] = chstatdef.[WFSTATUSID] 
			/* Match tickets to sites and then sites to accounts */
			LEFT JOIN [AccountSiteMapping] [asm] ON [cd].[SITEID] = [asm].[SITEID]
			LEFT JOIN [AccountDefinition] [ad] ON [asm].[ACCOUNTID] = [ad].[ORG_ID]

		) req_change_list
	WHERE
		/* Exclude test company */
		req_change_list.[Account] NOT LIKE 'TestCompany%' /* Exclude test company */

		/* Filter on Created Time within time range */
		AND 1 = CASE 
				WHEN @createdWithinRange != 1 THEN 1
				WHEN @createdWithinRange = 1 					
					AND req_change_list.[Created Time] >= @startDate
					AND req_change_list.[Created Time] < @endDate
					THEN 1
				ELSE 0
				END

		AND (
				(/* Ticket is a service request or incident (excluding Sales boards) that is NOT resolved or closed or the equivalent for Sales Order tickets */
				req_change_list.[Request Type] IN ('Service Request', 'Incident') 
				AND req_change_list.[Group] NOT IN ('Sales Quote', 'Sales Order')
				AND req_change_list.[Group] NOT LIKE 'Sales%'
				AND 1 = CASE 
				WHEN @openTickets != 1 THEN 1
				WHEN @openTickets = 1 
					AND req_change_list.[Request Status] NOT IN ('Resolved', 'Closed')
					AND req_change_list.[Request Status] NOT LIKE 'Sales Order Complete%'
					AND req_change_list.[Request Status] NOT LIKE 'Sales Order Cancelled%'
					--AND req_change_list.[Resolved Time] >= @startDate
					--AND req_change_list.[Resolved Time] < @endDate
					THEN 1
				ELSE 0
				END)
				OR
				(			
				(/*  Ticket is a Change that is NOT (in Close stage and has Completed status) */
				req_change_list.[Request Type] IN ('Change')
				AND 1 = CASE 
				WHEN @openChanges != 1 THEN 1
				WHEN @openChanges = 1 
					AND req_change_list.[Request Status] NOT IN ('Close: Completed', 'Close: Canceled')
					--AND req_change_list.[Resolved Time] >= @startDate
					--AND req_change_list.[Resolved Time] < @endDate
					THEN 1
				ELSE 0
				END
				)
				OR
				(/* Ticket is a sales ticket that has NOT been resolved */
				@salesTickets = 1 
				AND (
					req_change_list.[Request Type] IS NULL 
					OR req_change_list.[Request Type] IN ('Sales/Other')
					OR req_change_list.[Group] IN ('Sales Quote', 'Sales Order')
					OR req_change_list.[Group] LIKE 'Sales%'
					)
				AND 
				1 = CASE 
				WHEN @openTickets != 1 THEN 1
				WHEN @openTickets = 1 
					AND req_change_list.[Request Status] NOT IN ('Resolved', 'Closed')
					--AND req_change_list.[Resolved Time] >= @startDate
					--AND req_change_list.[Resolved Time] < @endDate
					THEN 1
				ELSE 0
				END)
			)
		)
	) req_change_list_final


	/* Join req_change_list table to 2 separate timespent tables */
	LEFT JOIN (
	

	/* Query to produce unfiltered Time Spent fact table */
	SELECT
		timespent_notfiltered.[Request ID]
		,timespent_notfiltered.[Request Type]
		,SUM(timespent_notfiltered.[Time Spent (minutes)]) AS [Time Spent in Total (minutes)]
	FROM (
		/* timespent_notfiltered table: shows worklogs across all time, for all requests and changes. */
		SELECT 
			timespent.* 
		FROM
			(/* (1) Timespent subquery for requests - Gets unit report (worklogs) records for requests */
			SELECT 
				ct.[CHARGEID] AS [Worklog ID]
				,ISNULL(rtdef.[NAME],'Sales/Other') AS [Request Type]
				,CAST([wo].[WORKORDERID] as varchar(8)) AS [Request ID]
				--,ct.[TECHNICIANID]
				,aaauser.[FIRST_NAME] AS [Technician]
				,ISNULL(ct.[DESCRIPTION],'') AS [Worklog Description]
				,CASE 
					WHEN [womf].[UDF_CHAR2] LIKE '%Yes%' THEN CONCAT(ISNULL([wtd].[NAME], 'In Hours'), '-', 'Project ', ISNULL([wlf].[UDF_CHAR1],''))
					ELSE CONCAT(ISNULL([wtd].[NAME], 'In Hours'), '-', '', ISNULL([wlf].[UDF_CHAR1],''))
					END AS [Work Type] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,ISNULL([wtd].[NAME], 'In Hours') AS [Time Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,CASE 
					WHEN [womf].[UDF_CHAR2] LIKE '%Yes%' THEN CONCAT('Project ', ISNULL([wlf].[UDF_CHAR1],''))
					ELSE ISNULL([wlf].[UDF_CHAR1], '')
					END AS [Location Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_STARTTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog Start]		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_ENDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog End]
				,ct.[TIMESPENT]/1000/60 AS [Time Spent (minutes)]

			FROM
				/* Charges (worklogs) table */
				[ChargesTable] ct WITH(NOLOCK) 
				/* Map to tickets */
				LEFT JOIN [WorkOrderToCharge] wotoc ON ct.[CHARGEID] = wotoc.[CHARGEID]
				LEFT JOIN [WorkOrder] wo ON wotoc.[WORKORDERID] = wo.[WORKORDERID]
				/* Request type */
				LEFT JOIN [WorkOrderStates] wos ON wo.[WORKORDERID] = wos.[WORKORDERID] 
				LEFT JOIN [RequestTypeDefinition] rtdef ON wos.[REQUESTTYPEID] = rtdef.[REQUESTTYPEID] 
				/* Worklog type - hours */
				LEFT JOIN [WorkLogTypeDefinition] wtd ON ct.[WORKLOGTYPEID] = wtd.[WORKLOGTYPEID] 
				/* Worklog type - location */
				LEFT JOIN [WorkLog_Fields] wlf ON [ct].[CHARGEID]=[wlf].[WORKLOGID] 
				/* Project Weighting (custom multi field) */
				LEFT JOIN [WorkOrder_Multi_Fields] womf ON wo.[WORKORDERID]=womf.[WORKORDERID]
				/* Technician names */
				LEFT JOIN [AaaUser] aaauser ON ct.[TECHNICIANID] = aaauser.[USER_ID] 
			WHERE
				/* Exclude worklogs associated with nonexistent tickets */
				[wo].[WORKORDERID] IS NOT NULL

				/* Temporarily disable results from this subquery */
				--AND 0 = 1

			UNION ALL

			/* (2) Timespent subquery for Changes - Gets unit report (worklogs) records for Changes */
			SELECT 
				ct.[CHARGEID] AS [Worklog ID]
				,'Change' AS [Request Type]
				,CAST(CONCAT('C',cd.[CHANGEID]) as varchar(8)) AS [Request ID]
				--,ct.[TECHNICIANID]
				,aaauser.[FIRST_NAME] AS [Technician]
				,ISNULL(ct.[DESCRIPTION],'') AS [Worklog Description]
				,ISNULL([wlf].[UDF_CHAR2], '') AS [Work Type]	
				,ISNULL([wtd].[NAME], 'In Hours') AS [Time Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,ISNULL([wlf].[UDF_CHAR1], '') AS [Location Category]
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_STARTTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog Start]		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_ENDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog End]
				,ct.[TIMESPENT]/1000/60 AS [Time Spent (minutes)]

			FROM
				/* Charges (worklogs) table */
				[ChargesTable] ct WITH(NOLOCK) 
				/* Map to Changes */
				LEFT JOIN [ChangeToCharge] cc ON cc.[CHARGEID] = ct.[CHARGEID]
				LEFT JOIN [ChangeDetails] cd ON cc.[CHANGEID] = cd.[CHANGEID]
				/* Worklog type - hours */
				LEFT JOIN [WorkLogTypeDefinition] [wtd] ON [ct].[WORKLOGTYPEID]=[wtd].[WORKLOGTYPEID] 
				/* Worklog type - location */
				LEFT JOIN [WorkLog_Fields] [wlf] ON [ct].[CHARGEID]=[wlf].[WORKLOGID] 
				--/* Project Weighting (custom multi field) */
				--LEFT JOIN [WorkOrder_Multi_Fields] [womf] ON [wo].[WORKORDERID]=[womf].[WORKORDERID]
				/* Technician names */
				LEFT JOIN [AaaUser] aaauser ON ct.[TECHNICIANID] = aaauser.[USER_ID] 
			WHERE
				/* Exclude worklogs associated with nonexistent Changes */
				cd.[CHANGEID] IS NOT NULL

			) timespent
		WHERE
			/* Filter worklogs here - include all worklogs regardless of time range. */
			1=1
			--timespent.[Worklog Start] >= @startDate
			--AND timespent.[Worklog End] < @endDate


		) timespent_notfiltered

	GROUP BY
		timespent_notfiltered.[Request ID]
		,timespent_notfiltered.[Request Type]

	) timespent_notfiltered_final ON req_change_list_final.[Request ID] = timespent_notfiltered_final.[Request ID]

	/* Join req_change_list table to 2nd timespent table (filtered on time range) */
	LEFT JOIN (
	

	/* Query to produce filtered Time Spent fact table */
	SELECT
		timespent_filtered.[Request ID]
		,timespent_filtered.[Request Type]
		,SUM(timespent_filtered.[Time Spent (minutes)]) AS [Time Spent in Range (minutes)]
	FROM (
		/* timespent_notfiltered table: shows worklogs across all time, for all requests and changes. */
		SELECT 
			timespent.* 
		FROM
			(/* (1) Timespent subquery for requests - Gets unit report (worklogs) records for requests */
			SELECT 
				ct.[CHARGEID] AS [Worklog ID]
				,ISNULL(rtdef.[NAME],'Sales/Other') AS [Request Type]
				,CAST([wo].[WORKORDERID] as varchar(8)) AS [Request ID]
				--,ct.[TECHNICIANID]
				,aaauser.[FIRST_NAME] AS [Technician]
				,ISNULL(ct.[DESCRIPTION],'') AS [Worklog Description]
				,CASE 
					WHEN [womf].[UDF_CHAR2] LIKE '%Yes%' THEN CONCAT(ISNULL([wtd].[NAME], 'In Hours'), '-', 'Project ', ISNULL([wlf].[UDF_CHAR1],''))
					ELSE CONCAT(ISNULL([wtd].[NAME], 'In Hours'), '-', '', ISNULL([wlf].[UDF_CHAR1],''))
					END AS [Work Type] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,ISNULL([wtd].[NAME], 'In Hours') AS [Time Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,CASE 
					WHEN [womf].[UDF_CHAR2] LIKE '%Yes%' THEN CONCAT('Project ', ISNULL([wlf].[UDF_CHAR1],''))
					ELSE ISNULL([wlf].[UDF_CHAR1], '')
					END AS [Location Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_STARTTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog Start]		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_ENDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog End]
				,ct.[TIMESPENT]/1000/60 AS [Time Spent (minutes)]

			FROM
				/* Charges (worklogs) table */
				[ChargesTable] ct WITH(NOLOCK) 
				/* Map to tickets */
				LEFT JOIN [WorkOrderToCharge] wotoc ON ct.[CHARGEID] = wotoc.[CHARGEID]
				LEFT JOIN [WorkOrder] wo ON wotoc.[WORKORDERID] = wo.[WORKORDERID]
				/* Request type */
				LEFT JOIN [WorkOrderStates] wos ON wo.[WORKORDERID] = wos.[WORKORDERID] 
				LEFT JOIN [RequestTypeDefinition] rtdef ON wos.[REQUESTTYPEID] = rtdef.[REQUESTTYPEID] 
				/* Worklog type - hours */
				LEFT JOIN [WorkLogTypeDefinition] wtd ON ct.[WORKLOGTYPEID] = wtd.[WORKLOGTYPEID] 
				/* Worklog type - location */
				LEFT JOIN [WorkLog_Fields] wlf ON [ct].[CHARGEID]=[wlf].[WORKLOGID] 
				/* Project Weighting (custom multi field) */
				LEFT JOIN [WorkOrder_Multi_Fields] womf ON wo.[WORKORDERID]=womf.[WORKORDERID]
				/* Technician names */
				LEFT JOIN [AaaUser] aaauser ON ct.[TECHNICIANID] = aaauser.[USER_ID] 
			WHERE
				/* Exclude worklogs associated with nonexistent tickets */
				[wo].[WORKORDERID] IS NOT NULL

				/* Temporarily disable results from this subquery */
				--AND 0 = 1

			UNION ALL

			/* (2) Timespent subquery for Changes - Gets unit report (worklogs) records for Changes */
			SELECT 
				ct.[CHARGEID] AS [Worklog ID]
				,'Change' AS [Request Type]
				,CAST(CONCAT('C',cd.[CHANGEID]) as varchar(8)) AS [Request ID]
				--,ct.[TECHNICIANID]
				,aaauser.[FIRST_NAME] AS [Technician]
				,ISNULL(ct.[DESCRIPTION],'') AS [Worklog Description]
				,ISNULL([wlf].[UDF_CHAR2], '') AS [Work Type]	
				,ISNULL([wtd].[NAME], 'In Hours') AS [Time Category] /* Treat null value in worklog type (wtd.Name) as 'In Hours' */
				,ISNULL([wlf].[UDF_CHAR1], '') AS [Location Category]
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_STARTTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog Start]		
				,CONVERT(datetime,DATEADD(s, CONVERT(bigint, [ct].[TS_ENDTIME]/1000), '1970-01-01 00:00:00.000') AT TIME ZONE 'UTC' AT TIME ZONE 'GMT Standard Time',0) AS [Worklog End]
				,ct.[TIMESPENT]/1000/60 AS [Time Spent (minutes)]

			FROM
				/* Charges (worklogs) table */
				[ChargesTable] ct WITH(NOLOCK) 
				/* Map to Changes */
				LEFT JOIN [ChangeToCharge] cc ON cc.[CHARGEID] = ct.[CHARGEID]
				LEFT JOIN [ChangeDetails] cd ON cc.[CHANGEID] = cd.[CHANGEID]
				/* Worklog type - hours */
				LEFT JOIN [WorkLogTypeDefinition] [wtd] ON [ct].[WORKLOGTYPEID]=[wtd].[WORKLOGTYPEID] 
				/* Worklog type - location */
				LEFT JOIN [WorkLog_Fields] [wlf] ON [ct].[CHARGEID]=[wlf].[WORKLOGID] 
				--/* Project Weighting (custom multi field) */
				--LEFT JOIN [WorkOrder_Multi_Fields] [womf] ON [wo].[WORKORDERID]=[womf].[WORKORDERID]
				/* Technician names */
				LEFT JOIN [AaaUser] aaauser ON ct.[TECHNICIANID] = aaauser.[USER_ID] 
			WHERE
				/* Exclude worklogs associated with nonexistent Changes */
				cd.[CHANGEID] IS NOT NULL

			) timespent
		WHERE
			/* Filter worklogs here - only include worklogs within the time range. */
			timespent.[Worklog Start] >= @startDate
			AND timespent.[Worklog End] < @endDate


		) timespent_filtered

	GROUP BY
		timespent_filtered.[Request ID]
		,timespent_filtered.[Request Type]

	) timespent_filtered_final ON req_change_list_final.[Request ID] = timespent_filtered_final.[Request ID]

--WHERE
	/* Final filtering */
	--/* Only include incidents and service requests */
	--(req_change_list_final.[Request Type] <> 'Change' 
	--AND timespent_notfiltered_final.[Time Spent in Total (minutes)] IS NOT NULL
	--)
	--/* Include all changes regardless of whether any time was logged */
	--OR req_change_list_final.[Request Type] = 'Change' 

	--/* Only include 2nd Line and Network tickets */
	--AND req_change_list_final.[Group] IN ('2nd Line', 'Network')

--ORDER BY 
	--req_change_list_final.[Created Time] DESC