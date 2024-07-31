/* SW Mountpoint Utilisation
Create Date:        2021-11-09, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Report mountpoint capacity, free space and utilisation, rounded.
Description:        Used to investigate SW alerts on mountpoint utilisation (ad-hoc).
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
2021-08-05          Tom Ling			Initial script completed.
***************************************************************************************************/


SELECT 
	vm.[VirtualMachineID] as vmID
	,vm.[Name] AS vmName
	,vmvol.MountPoint
	,ROUND(ISNULL(vmvol.[Volumes Capacity (GB)],NULL),2) AS [Volumes Capacity (GB)]
	,ROUND(ISNULL(vmvol.[Volumes Free Space (GB)],NULL),2) AS [Volumes Free Space (GB)]
	,100*ROUND(1-vmvol.[Volumes Free Space (GB)] / NULLIF(vmvol.[Volumes Capacity (GB)],0),4) AS [Utilisation]
FROM 
	[SolarWindsOrion].[dbo].[VIM_VirtualMachines] vm
	LEFT JOIN (
		/* Volume Capacity subquery */
		SELECT 
			vmvol.[VirtualMachineID] AS vmID
			,CONVERT(float, vmvol.[Capacity]*1.0/(1024*1024*1024)) AS [Volumes Capacity (GB)]
			,CONVERT(float, vmvol.[FreeSpace]*1.0/(1024*1024*1024)) AS [Volumes Free Space (GB)]
			,vmvol.MountPoint
		FROM [SolarWindsOrion].[dbo].[VIM_VirtualMachineVolumes] vmvol
	) vmvol ON vm.[VirtualMachineID] = vmvol.[vmID]
--WHERE
	--vm.[Name] LIKE '%VM1%'
	--vmvol.[MountPoint] = 'J:\'
	--OR vmvol.[MountPoint] = 'G:\'
	--,vmName ASC
ORDER BY 
	[Utilisation] DESC