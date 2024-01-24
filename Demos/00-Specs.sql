/*
	What we gonna use:
		- Stackoverflow DB with 10GB (you can get it together with one of the dbatools 
		container instance 3 - SQL Server 2019)
		- We don't have an image with SQL Server 2022 but what I did and you can do too 
		is pull that one, download and restore the database from: 
			https://github.com/dataplat/docker/releases/download/1.0/StackOverflow2010.7z

		- SSMS v19.x
		- In case you are using older (before v18) versions, know that v18 brought some 
		goodies on the execution plans, like partial times for the operators, and v19 
		may be a bit faster to load - but depends on your CPU)
*/

/*
Microsoft SQL Server 2022 (RTM) - 16.0.1000.6 (X64) 
	Oct  8 2022 05:58:25 
	Copyright (C) 2022 Microsoft Corporation
	Developer Edition (64-bit) on Linux (Ubuntu 20.04.5 LTS) <X64>
*/
SELECT @@VERSION
GO

/*
	Max Memory: 4096 GB
	DoP: 4
	CTfP: 25
*/
SELECT * from sys.configurations
WHERE name like '%cost threshold for parallelism%'
OR name like '%degree%'
OR name = 'max server memory (MB)'

/*
	Databases Compatibility level
	We gonna play with this along the way too
*/
SELECT @@SERVERNAME, [Name], [compatibility_level]
FROM sys.databases


/*
	Show Scoped configurations
*/
USE StackOverflow
GO
SELECT * 
  FROM sys.database_scoped_configurations
GO
