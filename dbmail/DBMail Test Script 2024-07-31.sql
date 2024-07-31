/* DBMail Test Script
Create Date:        2022-10-27, updated 2024-07-31
Author:             Tom Ling
Purpose: 			For testing SQL Server sp_send_dbmail function.
Description:        Sends a test email in tab-delimited CSV format to the specified recipient 
					using the sp_send_dbmail function in msdb database. Requires the sender to 
					have the correct permissions to send mail and run the query. 
					Sysadmin rights required to schedule jobs in SQL Server Agent.
Call by:            N/A
Database:  			[DatabaseName]
Used By:            Operations Department
Parameter(s):       N/A
Usage:              Paste this script into a Job Step in SQL Server Agent.
					If the script is failing, check: (1) all numeric fields converted to varchar,
					(2) variables declared correctly, (3) SELECT TOP 100 PERCENT if usinng ORDER BY
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2022-11-08          Tom Ling			Added @query_result_width and set to max (32767).
2022-10-28          Tom Ling			Added @execute_query_database parameter.
2022-10-27          Tom Ling			Initial script completed.
***************************************************************************************************/

/* Execute as a specific user (can avoid errors when scheduling the job in SQL Server Agent */
--EXECUTE AS USER = 'username'

/* If a hack is needed to force Excel to recognise the attachment as CSV */
/* See https://www.purplefrogsystems.com/2014/04/excel-doesnt-open-csv-files-correctly-from-sp_send_dbmail/ */
--DECLARE @Column1Name VARCHAR(255)
--SET @Column1Name = '[sep=,' + CHAR(13) + CHAR(10) + 'Column1]'

/* Otherwise, this sets the separator to a tab */
DECLARE @separator CHAR(1)
SET @separator = CHAR(9)

/* File attachment name. */
DECLARE @AttachmentName VARCHAR(255)
SET @AttachmentName = 
	'TestDBMailResult' 
	/* Add timestamp in format YYYY-MM-DD_hh-mm-ss and add file extension */
	+ '_' + REPLACE(REPLACE(CONVERT(char(19),CURRENT_TIMESTAMP, 120),' ','_'),':','-') 
	--SELECT @AttachmentName

DECLARE @AttachmentNameExtension VARCHAR(255)
SET @AttachmentNameExtension = @AttachmentName
	 + '.csv'

/* Set query here. Single quotes must be escaped. */
/* NOCOUNT is set on and off around the query to hide the 'rows affected' output line. */
DECLARE @Query VARCHAR(MAX)

/* If using the column1 hack */
--SET @Query = 'SELECT Column1 AS ' + @Column1Name + ', Column2, Column3 FROM myTable'

SET @Query = 'SET NOCOUNT ON 
SET QUOTED_IDENTIFIER ON ' + 

/* Hardcode the column names in the query result here (if needed). Otherwise comment 
this section out and comment out the @query_result_header parameter. */
--'SELECT 
--	''result'' AS result
--	,''column2'' AS column2
--	UNION ALL ' +

/* Query goes here between the opening and closing single quotes. 
Single quotes in the query must be escaped. */
/* Numeric datatypes must be converted to varchar or nvarchar if hardcoding column names 
in the previous section. */
'
SELECT @@LANGUAGE AS ''Language Name'';
'

/* Turn off NOCOUNT */
+ ' SET NOCOUNT OFF'


EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'Operations Department User'
	,@recipients ='recipients@company.com'
	,@query_result_width = 32767
	,@query_result_separator = @separator
	,@query = @Query
    --,@execute_query_database = [DatabaseName] --If the required database wasn't specified fully in the query, add it here.
	,@subject ='Test SQL Server email'
	,@body = @AttachmentName
    ,@attach_query_result_as_file = 1 
	,@query_attachment_filename = @AttachmentName
	,@query_result_no_padding = 1
--	,@query_result_header = 0
; 