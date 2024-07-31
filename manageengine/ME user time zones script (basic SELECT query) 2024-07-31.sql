/* ME user time zones
Create Date:        2020-10-21, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Identify ManageEngine users with the wrong time zone.
Description:        Returns a list of users in ManageEngine who have a time zone that is incorrect
					(users should have the Europe/London timezone, especially our internal users).
Call by:            N/A
Database:  			[manageengine]
Used By:            Operations Department
Parameter(s):       N/A
Usage:              Run script ad-hoc.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2021-08-31          Tom Ling			Documentation added. Cleaned up script.
2020-10-21          Tom Ling			Initial script completed.
***************************************************************************************************/

SELECT 
	sdup.[USERID] AS [User ID]
	,aaauser.[FIRST_NAME] AS [User]
	,sdup.[TIMEZONEID] AS [Time Zone ID]
	,tzd.[DISPLAYNAME] AS [Time Zone Name]
	,tzd.[TIMEZONECODE] AS [Time Zone Code]
	--,sdup.[DATE_FORMAT]
	--,sdup.[TIME_FORMAT]
	--,sdup.[SIGNATURE]
	--,sdup.[KBSHORTCUTS]
	--,sdup.[PROFILE_PIC_PATH]
FROM 
	[servicedesk].[dbo].[SDUserProfile] sdup
	/* Time Zone table */
	LEFT JOIN [servicedesk].[dbo].[TimeZoneDefinition] tzd ON sdup.[TIMEZONEID] = tzd.[TIMEZONEID]
	/* User info table */
	LEFT JOIN [servicedesk].[dbo].[AaaUser] aaauser ON sdup.[USERID] = aaauser.[USER_ID]
WHERE 
	tzd.[TIMEZONECODE] <> 'Europe/London' /* Users with the wrong time zone */