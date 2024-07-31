/* Create database script
Create Date:        2021-08-06, updated 2024-07-31
Author:             Tom Ling
Purpose: 			Generates a model database for testing and ad-hoc analysis purposes. 
Description:        Generates a model database for testing and ad-hoc analysis purposes. 
Call by:            N/A
Database:  			A new database
Used By:            Data Analyst
Parameter(s):       N/A
Usage:              You may need to run this on the SQL server in SQLCMD Mode 
					(Query menu -> SQLCMD Mode). 
****************************************************************************************************
CHANGELOG
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2024-07-31			Tom Ling			Portfolio version.
2021-08-06          Tom Ling			Initial script completed.
***************************************************************************************************/

--:CONNECT '0.0.0.0'

/* Create a new test database */
CREATE DATABASE DatabaseName
GO

/* Switch the Query Editor connection to the test database */
USE [DatabaseName]
GO

/* Create a table */
CREATE TABLE dbo.ListC  
   (ProductID int PRIMARY KEY NOT NULL,  
   ProductName varchar(25) NOT NULL,  
   Price money NULL,  
   ProductDescription varchar(max) NULL)  
GO  