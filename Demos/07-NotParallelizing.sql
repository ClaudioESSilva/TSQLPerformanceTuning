/*
	RUN THIS ON SQL Server 2022 TO CHECK THE GOODIES!
	GOODIES != GOING PARALLEL ????
*/

/*********************************
	TURN EXECUTION PLAN ON!

	SET STATISTICS TIME, IO ON
*********************************/
USE StackOverflow
GO


-- Show me what you got!
SELECT TOP 100 Id, ClosedDate, CreationDate, Tags
  FROM Posts
 WHERE ParentId = 50

-- What if I want it slower?! 
SELECT TOP 100 Id, ClosedDate, CreationDate, Tags
  FROM Posts
 WHERE ParentId = 50
OPTION (MAXDOP 1)



/********************
	INSERT...SELECT
********************/
/*
	Not parallel INSERT..SELECT
	Compatibility level 2014
*/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 120;
GO






DROP TABLE IF EXISTS #NotGoingParallel
GO

CREATE TABLE #NotGoingParallel
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO #NotGoingParallel
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618
GO
















-- But I heard that using "WITH (TABLOCK)" I would be able to get PARALLEL insert operation...
INSERT INTO #NotGoingParallel WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618 -- 518 records
GO

/*
	To be able to get a parallel INSERT..SELECT we need...
	Now with the right COMPATIBILITY_LEVEL 130 (SQL Server 2016)
*/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 130;
GO

/*
	Notice the "WITH (TABLOCK)"
*/
INSERT INTO #NotGoingParallel WITH (TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618
GO


/*
	NOTE: With less records to be inserted it can decide to still do a SERIAL INSERT
*/
INSERT INTO #NotGoingParallel WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 11
GO


/*
	Tipping point in this example
*/
INSERT INTO #NotGoingParallel WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT TOP 344 -- <-- Look here
		Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618
GO


INSERT INTO #NotGoingParallel WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
SELECT TOP 345 -- <-- Look here
		Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618
GO

DROP TABLE IF EXISTS #NotGoingParallel
GO






/********************
	TABLE VARIABLES
********************/
-- To be able to get a parallel INSERT..SELECT we need...
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 150;
GO

/*
	Scenario: Let's grab a couple of records to a table variable that will be used later
*/
DECLARE @TableParameter TABLE
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO @TableParameter (Id, ClosedDate, CreationDate, Tags)
SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  FROM Posts
 WHERE ParentId = 184618

/*
	Do we have data? Sure thing
*/
 SELECT Id, ClosedDate, CreationDate, Tags
  FROM @TableParameter


/*
	Side note: prior to SQL Server 2019 estimates where pretty bad... 1 row
*/
 SELECT Id, ClosedDate, CreationDate, Tags
  FROM @TableParameter
  OPTION (USE HINT('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_140'))










-- But why hasn't it gone parallel? TableVariableTransactionsDoNotSupportParallelNestedTransaction

/*
	BEFORE MOVE ON, SHOW THE EXECUTION PLAN ON SQL SERVER 2019 INSTANCE 
		- SHOW THE TableVariableTransactionsDoNotSupportParallelNestedTransaction - or not there?
*/


-- A "workaround" (using dynamic SQL)
DECLARE @TableParameterWA TABLE
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)
INSERT @TableParameterWA
EXEC(N'SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  FROM Posts
 WHERE ParentId = 184618')



 
/********************
	TEMP TABLES
********************/
/*
	RUN THIS!
*/
DROP TABLE IF EXISTS #NotTableParameter
GO
DROP TABLE IF EXISTS #NotTableParameterINTO
GO
DROP TABLE IF EXISTS #NotTableParameterINTONotParallel
GO

-- Not parallel SELECT..INTO
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 110;
GO

CREATE TABLE #NotTableParameter
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

INSERT INTO #NotTableParameter (Id, ClosedDate, CreationDate, Tags)
SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  FROM Posts
 WHERE ParentId = 184618


/* 
	Now, with a PARALLEL SELECT...INTO! No? But that exists, I'm sure!
*/
SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  INTO #NotTableParameterINTO
  FROM Posts
 WHERE ParentId = 184618

/* 
	No?! Why?!
*/





/* 
	Check current compatibility_level
*/
SELECT [name], [compatibility_level]
  FROM sys.databases
 WHERE [name] = 'StackOverflow'

/*
	This feature only appears on SQL Server 2014 (CL = 120)...So what if we change the CL?
*/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 120;
GO

SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  INTO #NotTableParameterINTONowParallel
  FROM Posts
 WHERE ParentId = 184618


/*
	That means if I'm running with a query hint for a lower CL it will not going parallel, right?
*/
SELECT TOP 10000 Id, ClosedDate, CreationDate, Tags
  INTO #NotTableParameterINTONotParallel
  FROM Posts
 WHERE ParentId = 184618
OPTION (USE HINT('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110'))








/*
	Still parallel?
	Yes...per docs (https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver16):
		QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_n
			"It doesn't affect other features of SQL Server that may depend on the database compatibility level"
*/

/*
	RUN THIS!
*/
DROP TABLE IF EXISTS #NotTableParameterINTONotParallel100
GO
DROP TABLE IF EXISTS #NotTableParameterINTONowParallel120
GO

ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 100;
GO

SELECT COUNT(1) AS Total, ParentId
  INTO #NotTableParameterINTONotParallel100
  FROM Posts
GROUP BY ParentId
ORDER BY 1 DESC
GO

/*
	Change to 2014 (can be higher)
*/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 120;
GO

SELECT COUNT(1) AS Total, ParentId
  INTO #NotTableParameterINTONowParallel120
  FROM Posts
GROUP BY ParentId
ORDER BY 1 DESC
GO



/*
	Even with CL 2014 it was possible to get a parallel plan
*/




/*******************
	FUNCTIONS
*******************/
-- Set to before the goodies
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 140;
GO

CREATE OR ALTER FUNCTION dbo.GiveMeTheDate 
(
	@datetime datetime
)
RETURNS datetime
AS
BEGIN
	/* Add something that prevent UDF to become inlinable */
	DECLARE @internalDT datetime = GETDATE()  

	RETURN @datetime
END
GO

SELECT TOP 10
		  COUNT(1) AS Total
		, ParentId
		, dbo.GiveMeTheDate(GETDATE())
  FROM Posts
GROUP BY ParentId
GO



-- But nowadays we have goodies (as-in INLINABLE), right? right?!
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 160;
GO

-- Check configuration_id = 10
SELECT * FROM sys.database_scoped_configurations

SELECT TOP 10
		  COUNT(1) AS Total
		, ParentId
		, dbo.GiveMeTheDate(GETDATE())
  FROM Posts
GROUP BY ParentId
GO

/*
	Check the INLINABLE option
*/
SELECT * FROM sys.sql_modules
WHERE OBJECT_NAME(object_id) = 'GiveMeTheDate'
GO

/*
	Change the function so it can be inlinable
*/
CREATE OR ALTER FUNCTION dbo.GiveMeTheDate 
(
	@datetime datetime
)
RETURNS datetime
AS
BEGIN	
	RETURN @datetime
END
GO

SELECT TOP 10
		  COUNT(1) AS Total
		, ParentId
		, dbo.GiveMeTheDate(GETDATE())
  FROM Posts
GROUP BY ParentId
GO

/*
	List of rules to be respected: 
		https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver16#requirements
*/



/*
	NON PARALLEL PLAN REASONS

	Full list here: 
		https://learn.microsoft.com/en-us/sql/relational-databases/query-processing-architecture-guide?view=sql-server-ver15#parallel-query-processing

	NONPARALLELPLANREASON											DESCRIPTION
	----------------------------------------------------------------------------------------------------------------------------------------------
	MaxDOPSetToOne													Maximum degree of parallelism set to 1.
	EstimatedDOPIsOne												Estimated degree of parallelism is 1.
	NoParallelWithRemoteQuery										Parallelism isn't supported for remote queries.
	NoParallelDynamicCursor											Parallel plans not supported for dynamic cursors.
	NoParallelFastForwardCursor										Parallel plans not supported for fast forward cursors.
	NoParallelCursorFetchByBookmark									Parallel plans not supported for cursors that fetch by bookmark.
	NoParallelCreateIndexInNonEnterpriseEdition						Parallel index creation not supported for non-Enterprise edition.
	NoParallelPlansInDesktopOrExpressEdition						Parallel plans not supported for Desktop and Express edition.
	NonParallelizableIntrinsicFunction								Query is referencing a non-parallelizable intrinsic function.
	CLRUserDefinedFunctionRequiresDataAccess						Parallelism not supported for a CLR UDF that requires data access.
	TSQLUserDefinedFunctionsNotParallelizable						Query is referencing a T-SQL User Defined Function that wasn't parallelizable.
	TableVariableTransactionsDoNotSupportParallelNestedTransaction	Table variable transactions don't support parallel nested transactions.
	DMLQueryReturnsOutputToClient									DML query returns output to client and isn't parallelizable.
	MixedSerialAndParallelOnlineIndexBuildNotSupported				Unsupported mix of serial and parallel plans for a single online index build.
	CouldNotGenerateValidParallelPlan								Verifying parallel plan failed, failing back to serial.
	NoParallelForMemoryOptimizedTables								Parallelism not supported for referenced In-Memory OLTP tables.
	NoParallelForDmlOnMemoryOptimizedTable							Parallelism not supported for DML on an In-Memory OLTP table.
	NoParallelForNativelyCompiledModule								Parallelism not supported for referenced natively compiled modules.
	NoRangesResumableCreate											Range generation failed for a resumable create operation.
	
*/

/**************************
	USING OUTPUT CLAUSE
**************************/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 130;
GO

/*
	Parallelism
		An OUTPUT clause that returns results to the client, or table variable, will always use a serial plan.

		In the context of a database set to compatibility level 130 or higher, if an INSERT...SELECT operation uses a WITH (TABLOCK) hint for the SELECT statement and 
		also uses OUTPUT...INTO to insert into a temporary or user table, then the target table for the INSERT...SELECT will be eligible for parallelism depending on 
		the subtree cost. The target table referenced in the OUTPUT INTO clause won't be eligible for parallelism.
		https://learn.microsoft.com/en-us/sql/t-sql/queries/output-clause-transact-sql?view=sql-server-ver16
*/

/*
	Prove it!
*/
DROP TABLE IF EXISTS #NotTableParameter
GO
CREATE TABLE #NotTableParameter
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

DECLARE @TableParameterAsOutput TABLE
(
	  Id int
)

INSERT INTO #NotTableParameter WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
OUTPUT inserted.Id
INTO @TableParameterAsOutput
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618
GO


/*
	Use either a #temp table or a user table to get parallelism
	Still need the WITH (TABLOCK)
	
	Do good testing! BE AWARE OF THE LOCKING THIS WILL CAUSE!
*/

DROP TABLE IF EXISTS #NotTableParameter
GO
CREATE TABLE #NotTableParameter
(
	  Id			int
	, ClosedDate	datetime
	, CreationDate	datetime
	, Tags			nvarchar(150)
)

DROP TABLE IF EXISTS #TempTableAsOutput
GO
CREATE TABLE #TempTableAsOutput
(
	  Id int
)


INSERT INTO #NotTableParameter WITH(TABLOCK) 
(
	  Id
	, ClosedDate
	, CreationDate
	, Tags
) 
OUTPUT inserted.Id
INTO #TempTableAsOutput
SELECT Id, ClosedDate, CreationDate, Tags
  FROM Posts 
 WHERE ParentId = 184618


-- Show the results exists
SELECT * 
  FROM #TempTableAsOutput