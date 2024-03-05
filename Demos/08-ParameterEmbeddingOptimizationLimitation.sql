/*
	Parameter Embedding Optimization is cool! 
	Until...we hit a limitation

	Paul White explains:
		"Sniffing parameter values allows the optimizer to use the parameter value to derive cardinality estimates. 
		Both WITH RECOMPILE and OPTION (RECOMPILE) result in query plans with estimates calculated from the actual 
		parameter values on each execution.

		The	Parameter Embedding Optimization takes this process a step further. 
		Query parameters are replaced with literal constant values during query parsing."
	Source: https://sqlperformance.com/2013/08/t-sql-queries/parameter-sniffing-embedding-and-the-recompile-options
*/
USE StackOverflow
GO

-- Make sure you have an index on the Posts table OwnerUserId column
-- DROP INDEX NCI_Posts_OwnerUserId ON Posts
CREATE INDEX NCI_Posts_OwnerUserId ON Posts(OwnerUserId)
GO



-- Stored Procedure spNumberOfPosts
CREATE OR ALTER PROC spNumberOfPosts 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT COUNT(1) AS NumberOfPosts
	  FROM dbo.Posts
	 WHERE (
					OwnerUserId = @OwnerUserId 
				 OR @OwnerUserId IS NULL
			)

END
GO


-- Let's test it! Index Seek, right?
EXEC spNumberOfPosts @OwnerUserId = 50;
GO


-- Stored Procedure spNumberOfPosts
CREATE OR ALTER PROC spNumberOfPosts 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT COUNT(1) AS NumberOfPosts
	  FROM dbo.Posts
	 WHERE (
					OwnerUserId = @OwnerUserId 
				 OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

END
GO


-- Now it's an Index Seek, right?
EXEC spNumberOfPosts @OwnerUserId = 50;
GO




-- Stored Procedure spNumberOfPosts
CREATE OR ALTER PROC spNumberOfPosts 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Value INT

	SELECT @Value = COUNT(1)
	  FROM dbo.Posts
	 WHERE (
					OwnerUserId = @OwnerUserId 
				 OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

	SELECT @Value AS NumberOfPosts

END
GO

-- What's the problem? Sure, it will be Index Seek! No?
EXEC spNumberOfPosts @OwnerUserId = 50;
GO



-- Stored Procedure spNumberOfPosts
CREATE OR ALTER PROC spNumberOfPosts 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Value INT

	SELECT COUNT(1) AS NumberOfPosts
	  INTO #TMP
	  FROM dbo.Posts
	 WHERE (
					OwnerUserId = @OwnerUserId 
				 OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

	SELECT @Value = NumberOfPosts
	  FROM #TMP

	SELECT @Value AS NumberOfPosts

END
GO


-- Does this fix it?!
EXEC spNumberOfPosts @OwnerUserId = 50;
GO







/***************************
		ALL TOGETHER
***************************/
SET STATISTICS TIME, IO ON
GO

-- Stored Procedure spNumberOfPosts_original
CREATE OR ALTER PROC spNumberOfPosts_original 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT COUNT(1) AS NumberOfPosts
	  FROM dbo.Posts
	 WHERE (
				OwnerUserId = @OwnerUserId 
				OR @OwnerUserId IS NULL
			)

END
GO


-- Stored Procedure spNumberOfPosts_recompile
CREATE OR ALTER PROC spNumberOfPosts_recompile 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT COUNT(1) AS NumberOfPosts
	  FROM dbo.Posts
	 WHERE (
				OwnerUserId = @OwnerUserId 
				OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

END
GO


-- Stored Procedure spNumberOfPosts_recompileVar
CREATE OR ALTER PROC spNumberOfPosts_recompileVar 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Value INT

	SELECT @Value = COUNT(1)
	  FROM dbo.Posts
	 WHERE (
				OwnerUserId = @OwnerUserId 
				OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

	SELECT @Value AS NumberOfPosts

END
GO



-- Stored Procedure spNumberOfPosts_recompileVarWorkaround
CREATE OR ALTER PROC spNumberOfPosts_recompileVarWorkaround 
	@OwnerUserId AS INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Value INT

	SELECT COUNT(1) AS NumberOfPosts
	  INTO #TMP
	  FROM dbo.Posts
	 WHERE (
				OwnerUserId = @OwnerUserId 
				OR @OwnerUserId IS NULL
			)
	OPTION (RECOMPILE)

	SELECT @Value = NumberOfPosts
	  FROM #TMP

	SELECT @Value AS NumberOfPosts

END
GO


-- Let's test it! Index Seek, right?
EXEC spNumberOfPosts_original @OwnerUserId = 50;
GO

-- Now it's an Index Seek, right?
EXEC spNumberOfPosts_recompile @OwnerUserId = 50;
GO

-- What's the problem? Sure, it will be Index Seek! No?
EXEC spNumberOfPosts_recompileVar @OwnerUserId = 50;
GO

-- Does this fix it?!
EXEC spNumberOfPosts_recompileVarWorkaround @OwnerUserId = 50;
GO

