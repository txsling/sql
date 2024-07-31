/* Rename database
Create Date:        2022-03-17, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Rename a database
Description:        Forces a database rename when the target database can't be exclusively locked.
Call by:            N/A
Database:  			N/A
Used By:            Data Analyst
Parameter(s):       N/A
Usage:              Use with caution. Sets a database to single-user mode temporarily. Better to use
					SSMS graphical user interface to rename the database, and only use this script
					if that operation fails.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2022-03-17          Tom Ling			Initial script completed.
***************************************************************************************************/


USE [master];
GO

/* Set old (initial) name of database here */
ALTER DATABASE Database_old_name SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

/* Set old and new name of database here */
EXEC sp_renamedb N'Database_old_name', N'Database_new_name';

/* Reset database to multi-user mode (add new name of database here) */
ALTER DATABASE Database_new_name SET MULTI_USER WITH ROLLBACK IMMEDIATE;