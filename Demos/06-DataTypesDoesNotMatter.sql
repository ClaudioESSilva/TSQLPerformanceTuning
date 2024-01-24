USE [StackOverflow]
GO

IF OBJECT_ID('TSQLDataTypes') IS NOT NULL
  DROP TABLE TSQLDataTypes
GO

SELECT TOP 10000 IDENTITY(Int, 1,1) AS TSQLID, 
       'TSQL ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS TSQLName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO TSQLDataTypes
  FROM master.sys.all_columns A
 CROSS JOIN master.sys.all_columns B
 CROSS JOIN master.sys.all_columns C
 CROSS JOIN master.sys.all_columns D
GO
ALTER TABLE TSQLDataTypes ADD CONSTRAINT PK_TSQLDataTypes PRIMARY KEY(TSQLID)
GO


/*
  DROP INDEX NCI_TSQLName ON TSQLDataTypes
*/
CREATE INDEX NCI_TSQLName ON TSQLDataTypes(TSQLName)
GO

SELECT TOP 10 *
FROM TSQLDataTypes
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

DECLARE @Name nvarchar(200)
SET @Name = N'ReplaceHere'

/*
  What gonna happen? Seek or scan?
*/
SELECT * 
  FROM TSQLDataTypes
 WHERE TSQLName = @Name
GO



DECLARE @Name varchar(200)
SET @Name = 'ReplaceHere'

/*
  What gonna happen? Seek or scan?
*/
SELECT * 
  FROM TSQLDataTypes
 WHERE TSQLName = @Name
GO





/*
	WHAT ABOUT PARTITIONED TABLES?

	NOTE: Partitioning is NOT a PERFORMANCE feature!
		  However, if you can leverage on it to make queries faster....why not? :-) 
*/

USE StackOverflow;
GO

/*
	TURN *OFF* ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO OFF
*/

/*
  ~17 sec to create
*/
IF OBJECT_ID('TabPartitionElimination') IS NOT NULL
  DROP TABLE TabPartitionElimination
GO
IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'myRangePS')
  DROP PARTITION SCHEME myRangePS
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'myRangePF')
  DROP PARTITION FUNCTION myRangePF
GO

CREATE PARTITION FUNCTION myRangePF (INT)
AS RANGE LEFT FOR VALUES
(   100,
    500,
    1000,
    1500
);

CREATE PARTITION SCHEME myRangePS AS PARTITION myRangePF ALL TO ([PRIMARY]);
GO

CREATE TABLE TabPartitionElimination
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON myRangePS (Col1);
GO

IF OBJECT_ID('TabNonPartitioned') IS NOT NULL
  DROP TABLE TabNonPartitioned

CREATE TABLE TabNonPartitioned
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON [PRIMARY];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (ABS(CheckSUM(NEWID()) / 10000000), ABS(CheckSUM(NEWID()) / 10000000));
GO 20000
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (1001, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (1501, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
COMMIT
GO

/*
  Creating a CLUSTERED INDEX
*/
CREATE CLUSTERED INDEX CI_TabPartitionElimination ON [dbo].TabPartitionElimination (COL1)
GO

/*
  Copy all data from paritioned table to the non-partitioned
*/
INSERT INTO TabNonPartitioned
SELECT * FROM TabPartitionElimination
GO




/*
  Check the number of the partitions
*/
SELECT $partition.myRangePF(Col1) [Partition Number], * 
  FROM TabPartitionElimination
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON

	NOTE: Partitioning is NOT a PERFORMANCE feature!
		  However, if you can leverage on it to make queries faster....why not? :-) 
*/

/*
  Read only data from partition 5
*/
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 > 1500 /* Static partition elimination */
   AND 1 = 1 /* Get rid of the auto-parameterization - https://www.sql.kiwi/2012/09/why-doesn-t-partition-elimination-work.html */


/*
  Read only data from partition 4 & 5
*/
DECLARE @i INT = 1500
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= @i /* Dynamic partition elimination */


/*
  What about non-partitioned table?
*/
SELECT * 
  FROM TabNonPartitioned
 WHERE Col1 >= 1500
GO


/*
  Read only data from partition 4 & 5?
*/
DECLARE @i BIGINT = 1500
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= @i
/*
  How many partitions were read?!
*/





/*
	TURN *OFF* ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO OFF
*/
/*
	WHAT ABOUT DATES?

	NOTE: Partitioning is NOT a PERFORMANCE feature!
		  However, if you can leverage on it to make queries faster....why not? :-) 
*/

IF OBJECT_ID('TabPartitionEliminationDates') IS NOT NULL
  DROP TABLE TabPartitionEliminationDates
GO
IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'myDateRangePS')
  DROP PARTITION SCHEME myDateRangePS
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'myDateRangePF')
  DROP PARTITION FUNCTION myDateRangePF
GO

CREATE PARTITION FUNCTION myDateRangePF (DATETIME2(0))
AS RANGE LEFT FOR VALUES
(   '2020-01-01',
    '2021-01-01',
    '2022-01-01',
    '2023-01-01'
);

CREATE PARTITION SCHEME myDateRangePS AS PARTITION myDateRangePF ALL TO ([PRIMARY]);
GO

CREATE TABLE TabPartitionEliminationDates
(
    EventDT DATETIME2(0),
    EventEndDT DATETIME2(7),
    Col3 CHAR(1000) DEFAULT NEWID()
) ON myDateRangePS (EventDT);
GO

/*
  Creating a CLUSTERED INDEX
*/
CREATE CLUSTERED INDEX CI_TabPartitionEliminationDates ON [dbo].TabPartitionEliminationDates (EventDT) ON myDateRangePS (EventDT);
GO


SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
VALUES (DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01'), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01'));
GO 20000
INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
VALUES ('2022-01-02', DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2022-01-02'));
GO 100 
INSERT INTO TabPartitionEliminationDates (EventDT, EventEndDT)
VALUES ('2023-01-02', DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2023-01-02'));
GO 100
COMMIT
GO


SELECT $partition.myDateRangePF(EventDT) [Partition Number], * 
  FROM TabPartitionEliminationDates
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

/*
  How many partitions were read?
*/
DECLARE @DT DATE = '2021-01-02'
SELECT EventDT 
  FROM TabPartitionEliminationDates
 WHERE EventDT >= @DT
GO


DECLARE @DT2 DATETIME2(7) = DATEADD(dd, -300, GETDATE())
DECLARE @batch bigint = 1000

SELECT TOP (@batch) EventDT
  FROM TabPartitionEliminationDates
 WHERE EventDT > @DT2
GO

DECLARE @DT3 DATETIME2(0) = DATEADD(dd, -300, GETDATE())
DECLARE @batch2 bigint = 1000

SELECT TOP (@batch2) EventDT
  FROM TabPartitionEliminationDates
 WHERE EventDT > @DT3
GO



/*
	Bottom line:
		- Avoid implicit convertions.
		- Make sure you use variables of the same data types as our table columns
		  That will also help getting partition elimination if possible
*/