/* Commvault Library Size
Create Date:        2021-11-25, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Used to show a client how much space they have left in their Commvault Library.
Description:        Returns Library capacity, used, and free space on each mountpath. 
					Based on a Library and Drive Size script, but summing across all mountpaths.
					Utilisation % added and only GB columns included. 
Call by:            SQL Server Agent job on the Commvault Database server
Database:  			[Commvault Database]
Used By:            Operations Department
Parameter(s):       Library name parameter in WHERE clause. 
Usage:              Numeric values are rounded to maintain MB level of accuracy.
					Handle rounding in the reporting layer.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2022-11-25          Tom Ling			Initial script completed.
***************************************************************************************************/

SELECT TOP 100 PERCENT
	result.[Library] AS [Library]
	,CAST(result.[TotalSpaceGB] AS DECIMAL(18,1)) AS [Capacity (GB)]
	,CAST(result.[UsedSpaceGB] AS DECIMAL(18,1)) AS [Used Space (GB)]
	,CAST(result.[FreeSpaceGB] AS DECIMAL(18,1)) AS [Free Space (GB)]
	,CAST(100*result.[UsedSpaceGB] / result.[TotalSpaceGB] AS DECIMAL(18,2)) AS [Utilisation %]

FROM (
	SELECT TOP 100 PERCENT
		--ccmi1.[mediaid] 
		--,ccmi2.[library]
		mmlib.[AliasName] AS [Library]
		--,LDview.[DriveAliasName] AS [Drive]
		--,MPview.[MountPathName] AS [Mountpath]
		,CAST(SUM(ccmi2.[totalspaceMB])*1.0/1024/1024 AS DECIMAL(18,6)) AS [TotalSpaceTB]
		--,CAST(SUM(ccmi2.[usedspaceMB])*1.0/1024/1024 AS DECIMAL(18,6)) AS [UsedSpaceTB] 
		/* Used space values aren't correct for some reason so calculate used space from capacity - free */
		,CAST((SUM(ccmi2.[totalspaceMB])-SUM(ccmi2.[freespaceMB]))*1.0/1024/1024 AS DECIMAL(18,6)) AS [UsedSpaceTB]
		,CAST(SUM(ccmi2.[freespaceMB])*1.0/1024/1024 AS DECIMAL(18,6)) AS [FreeSpaceTB]
		,CAST(SUM(ccmi2.[totalspaceMB])*1.0/1024 AS DECIMAL(18,3)) AS [TotalSpaceGB]
		--,CAST(SUM(ccmi2.[usedspaceMB])*1.0/1024 AS DECIMAL(18,3)) AS [UsedSpaceGB]
		/* Used space values aren't correct for some reason so calculate used space from capacity - free */
		,CAST((SUM(ccmi2.[totalspaceMB])-SUM(ccmi2.[freespaceMB]))*1.0/1024 AS DECIMAL(18,3)) AS [UsedSpaceGB]
		,CAST(SUM(ccmi2.[freespaceMB])*1.0/1024 AS DECIMAL(18,3)) AS [FreeSpaceGB]
	FROM 
		(/* Subquery to retrieve most recent media record for each mountpath*/
		SELECT DISTINCT 
			ccmi.[mediaid]
			,MAX(ccmi.[VolumeID]) AS [MaxVolumeID]
		FROM [CommServ].[dbo].[CommCellMediaInfo] ccmi
		GROUP BY 
			ccmi.[MediaID]) ccmi1
		/* Join to CCMI table to retrieve other relevant information for each mountpath */
		LEFT JOIN [CommServ].[dbo].[CommCellMediaInfo] ccmi2 ON ccmi1.[MaxVolumeID] = ccmi2.[volumeid]
		/* Join library table to get library names */
		LEFT JOIN [CommServ].[dbo].[MMMedia] mmmedia ON ccmi1.mediaid = mmmedia.[MediaId]
		LEFT JOIN [CommServ].[dbo].[MMLibrary] mmlib ON mmmedia.[LibraryId] = mmlib.[LibraryId]
		/* Map mediaid to drive name to get drive alias names */
		LEFT JOIN [CommServ].[dbo].[CNMMLibraryDrivesView] LDview ON ccmi2.[drivename] = LDview.[DriveName]
		/* Map drives to mount path IDs to get mount path names */
		LEFT JOIN [CommServ].[dbo].[CNMMMountPathView] MPview ON LDview.[MountPathID] = MPview.[MountPathID]

		WHERE
			mmlib.[AliasName] LIKE '%Client Name%' /* Accommodates Crystal Reports parameter for library name */

		GROUP BY
			mmlib.[AliasName]

		ORDER BY
			mmlib.[AliasName]
			--,MPview.[MountPathName]
			--,LDview.[DriveAliasName]

		) result