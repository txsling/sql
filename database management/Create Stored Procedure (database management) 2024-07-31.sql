/* Create Stored Procedure
Create Date:        2022-03-17, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Code snippets used to create or modify stored procedures.
Description:        Contains commented code snippets to create or drop stored procedures and 
					organise them under a custom schema. 
					Stored procedures can be edited under 
					Databases > (database) > Programmability > Stored Procedures.
Call by:            N/A
Database:  			N/A
Used By:            Data Analyst
Parameter(s):       N/A
Usage:              Use with caution. Best practice: copy out code snippets from here to assemble
					a CREATE PROCEDURE script within your external file. 
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2023-02-09			Tom Ling			Updated to reflect better practice of putting stored
										procedures in the database that they access.
2022-03-17          Tom Ling			Initial script completed.
***************************************************************************************************/

/* Tell SSMS which database to create the stored procedure in. */
/* Run this if you get a permissions error when attempting to create a stored procedure on FTOps. */
--USE [databasename]
--GO

/* Create a schema in the selected database with owner [dbo], if it doesn't already exist. */
/* Note that there needs to be the same named schema in each SQL Server Instance that you intend to use
the stored procedure in. */
/* This can be used to contain and organise stored procedures. */
--CREATE SCHEMA [SchemaName] AUTHORIZATION [dbo]

/* If the stored procedure already exists, use this to drop the existing stored procedure */
--DROP PROCEDURE SchemaName.uspTestStoredProc 
--GO

/* Execute a stored procedure (after it exists) */
--EXEC SchemaName.uspTestStoredProc 0
--or simply:
--SchemaName.uspTestStoredProc


/* STORED PROCEDURE CREATION TEMPLATE under SchemaName schema */
/* If the schema prefix is omitted the stored procedure is created under the [dbo] schema. */
/* The documentation block is automatically pulled in from the existing stored procedure 
when it is modified using the SSMS GUI. If the stored procedure is being newly created, 
edit the documentation block below before running the code. */


/* To use this script, highlight all the code below and execute. 
Don't include code from above this section, otherwise it will be added into the stored procedure. 
Alternatively, copy all the code below this line into a new Query window and then 
save it as a new script that generates a stored procedure. */




/* Stored Procedure
Create Date:        2022-03-01, last updated 2024-07-31
Author:             Tom Ling
Purpose: 			Short statement of why this procedure exists.
Description:        Verbose description of what the stored procedure does goes here. Be specific 
					and don't be afraid to say too much. More is better, than less, every single 
					time. Think about "what, when, where, how and why" when authoring a description.
Call by:            e.g. Audit Excel file
Database:  			e.g. [databasename]
Used By:            Operations Department
Parameter(s):       @param1 - description and usage
                    @param2 - description and usage
Usage:              Additional notes or caveats about this procedure, like where it can and 
					cannot be run, or gotchas to watch for when using it.
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31          Tom Ling			Initial script completed.
***************************************************************************************************/

CREATE OR ALTER PROCEDURE FTOps.uspTestStoredProc 

/* Parameters */
@param int = 0

AS
BEGIN 

/* Turn off rows affected messages */
SET NOCOUNT ON

SELECT * FROM sys.schemas

--end of stored procedure
END