/*
	The Copy & Paste pattern problem
*/
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 160;
GO

USE StackOverflow
GO

/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/
DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4

SELECT Id
  FROM dbo.Users AS U
 WHERE (
              EXISTS (SELECT 1 
						FROM dbo.Posts AS P
					   WHERE P.OwnerUserId = U.Id
					     AND P.Score = @param1 
						 AND P.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P2
					   WHERE P2.OwnerUserId = U.Id
					     AND P2.Score = @param2 
						 AND P2.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P3
					   WHERE P3.OwnerUserId = U.Id
					     AND P3.Score = @param3 
						 AND P3.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P4
					   WHERE P4.OwnerUserId = U.Id
					     AND P4.Score = @param4
						 AND P4.ViewCount = 10
					 )
       )
GO

/********************************
	Compare results here
		Table 'Posts'...

		Table 'Posts'...
********************************/


/*
	A real story!
	New request: Add a new validation for a new Score
*/

DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4
	  , @param5 INT = 5

SELECT Id
  FROM dbo.Users AS U
 WHERE (
              EXISTS (SELECT 1 
						FROM dbo.Posts AS P
					   WHERE P.OwnerUserId = U.Id
					     AND P.Score = @param1 
						 AND P.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P2
					   WHERE P2.OwnerUserId = U.Id
					     AND P2.Score = @param2 
						 AND P2.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P3
					   WHERE P3.OwnerUserId = U.Id
					     AND P3.Score = @param3 
						 AND P3.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P4
					   WHERE P4.OwnerUserId = U.Id
					     AND P4.Score = @param4
						 AND P4.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P5
					   WHERE P5.OwnerUserId = U.Id
					     AND P5.Score = @param5
						 AND P5.ViewCount = 10
					 )
       )
GO






/* 
	We can rewrite as the following
*/
DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4

SELECT Id
  FROM dbo.Users AS U
 WHERE EXISTS (
               SELECT 1
                 FROM dbo.Posts AS P
                WHERE P.OwnerUserId = U.Id
                  AND (
                           P.Score = @param1
                        OR P.Score = @param2
                        OR P.Score = @param3
                        OR P.Score = @param4
                      )
                  AND P.ViewCount = 10
		)
GO




DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4
	  , @param5 INT = 5

/* 
	We can rewrite as the following
*/
SELECT Id
  FROM dbo.Users AS U
 WHERE EXISTS (
               SELECT 1
                 FROM dbo.Posts AS P
                WHERE P.OwnerUserId = U.Id
                  AND (
                           P.Score = @param1
                        OR P.Score = @param2
                        OR P.Score = @param3
                        OR P.Score = @param4
						OR P.Score = @param5
                      )
                  AND P.ViewCount = 10
		)
GO



/*
	Side by side
*/
DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4

SELECT Id
  FROM dbo.Users AS U
 WHERE (
              EXISTS (SELECT 1 
						FROM dbo.Posts AS P
					   WHERE P.OwnerUserId = U.Id
					     AND P.Score = @param1 
						 AND P.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P2
					   WHERE P2.OwnerUserId = U.Id
					     AND P2.Score = @param2 
						 AND P2.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P3
					   WHERE P3.OwnerUserId = U.Id
					     AND P3.Score = @param3 
						 AND P3.ViewCount = 10
					 )
           OR EXISTS (SELECT 1 
						FROM dbo.Posts AS P4
					   WHERE P4.OwnerUserId = U.Id
					     AND P4.Score = @param4
						 AND P4.ViewCount = 10
					 )
       )
GO


DECLARE @param1 INT = 1
	  , @param2 INT = 2
	  , @param3 INT = 3
	  , @param4 INT = 4

SELECT Id
  FROM dbo.Users AS U
 WHERE EXISTS (
               SELECT 1
                 FROM dbo.Posts AS P
                WHERE P.OwnerUserId = U.Id
                  AND (
                           P.Score = @param1
                        OR P.Score = @param2
                        OR P.Score = @param3
                        OR P.Score = @param4
                      )
                  AND P.ViewCount = 10
		)
GO





/************************
	2nd example
************************/

/****************************************
		ADD AN INDEX
****************************************/
DROP INDEX NCI_Posts_OwnerUserId ON dbo.Posts
GO

CREATE NONCLUSTERED INDEX NCI_Posts_OwnerUserId ON dbo.Posts (OwnerUserId) 
GO


/*
	Not so dynamic code
*/
CREATE OR ALTER PROC dbo.MyReport
(
	  @StartDate	datetime
	, @EndDate		datetime
	, @UserId		int
)
AS
	BEGIN 
		SELECT OwnerUserId, COUNT(1) AS NumberOfPosts
		  FROM dbo.Posts
		 WHERE (
					 CreationDate >= @StartDate
				  OR @StartDate IS NULL
			   )
		   AND (
					 CreationDate < @EndDate
				  OR @EndDate IS NULL
			   )
		   AND (
					 OwnerUserId = @UserId
				  OR @UserId IS NULL
			   )
		GROUP BY OwnerUserId
	END
GO

/*
	Examples
*/
EXEC dbo.MyReport
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = NULL

EXEC dbo.MyReport
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
GO

/*
	Classic parameter sniffing problem
*/
EXEC dbo.MyReport
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = NULL
GO

/*
	DON'T RUN THIS IN PRODUCTION!
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

EXEC dbo.MyReport
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
GO

/*
	The copy & paste problem

	Losing a great opportunity to improve it
*/
CREATE OR ALTER PROC dbo.MyReport_1MoreParameter
(
	  @StartDate	datetime
	, @EndDate		datetime
	, @UserId		int
	, @CommentCount int
)
AS
	BEGIN
		SELECT OwnerUserId, COUNT(1) AS NumberOfPosts
		  FROM dbo.Posts
		 WHERE (
					 CreationDate >= @StartDate
				  OR @StartDate IS NULL
			   )
		   AND (
					 CreationDate < @EndDate
				  OR @EndDate IS NULL
			   )
		   AND (
					 OwnerUserId = @UserId
				  OR @UserId IS NULL
			   )
		   AND (
					 CommentCount >= @CommentCount
				  OR @CommentCount IS NULL
			   )
		GROUP BY OwnerUserId
	END
GO

/*
	Run both
*/
EXEC dbo.MyReport_1MoreParameter
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = NULL
		, @CommentCount = NULL

EXEC dbo.MyReport_1MoreParameter
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
		, @CommentCount = 10
GO




CREATE OR ALTER PROC dbo.MyReport_Dynamic
(
	  @StartDate	datetime
	, @EndDate		datetime
	, @UserId		int
	, @CommentCount int
)
AS
	BEGIN
		DECLARE @Sql nvarchar(4000)
		DECLARE @ParamDefinition nvarchar(2000)
		
		SET @ParamDefinition = '@StartDate datetime,
								@EndDate datetime,
								@UserId int,
								@CommentCount int'

		SET @Sql = 'SELECT OwnerUserId, COUNT(1) AS NumberOfPosts
					  FROM dbo.Posts 
					 WHERE 1 = 1 '

		IF @StartDate IS NOT NULL 
			SET @sql += ' AND CreationDate >= @StartDate'

		IF @EndDate IS NOT NULL 
			SET @sql += ' AND CreationDate < @EndDate'

		IF @UserId IS NOT NULL 
			SET @sql += ' AND OwnerUserId = @UserId'

		IF @CommentCount IS NOT NULL 
			SET @sql += ' AND CommentCount >= @CommentCount'

		SET @Sql += ' GROUP BY OwnerUserId'

		EXEC sp_executesql @Sql, 
							@ParamDefinition,
							@StartDate,
							@EndDate,	
							@UserId,	
							@CommentCount
	END
GO


/*
	DON'T RUN THIS IN PRODUCTION!
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT usecounts, cacheobjtype, objtype, text  
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE objtype IN ('Proc', 'Prepared')
AND text LIKE '%posts%'; 

/*
	Run the following 3
*/
EXEC dbo.MyReport
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
GO


EXEC dbo.MyReport_1MoreParameter
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
		, @CommentCount = NULL
GO


EXEC dbo.MyReport_Dynamic
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
		, @CommentCount = NULL
GO


/*
	2nd attempt - Run all 4
*/
EXEC dbo.MyReport_1MoreParameter
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
		, @CommentCount = 10
GO


EXEC dbo.MyReport_Dynamic
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = 50
		, @CommentCount = 10
GO

/*
	~30 seconds
*/
EXEC dbo.MyReport_1MoreParameter
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = NULL
		, @CommentCount = NULL
GO

EXEC dbo.MyReport_Dynamic
		@StartDate = NULL
		, @EndDate = NULL
		, @UserId = NULL
		, @CommentCount = NULL
GO


/******************************
		How's the cache?
******************************/
SELECT usecounts, cacheobjtype, objtype, text  
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE objtype IN ('Proc', 'Prepared')
AND text LIKE '%posts%'; 


/***************
	CLEAN UP
***************/
DROP INDEX NCI_Posts_OwnerUserId ON dbo.Posts
GO


/******************************************************************************************
	BOTTOM LINE:
		When you find stuff like this take an extra minute to check if will 
		make sense re-write instead of just append a couple of lines of code 
		to cross the finish line.
******************************************************************************************/