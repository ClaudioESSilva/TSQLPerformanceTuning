SET STATISTICS TIME, IO ON
GO

/*********************************
	TURN EXECUTION PLAN ON!

	SET STATISTICS TIME, IO ON
*********************************/



CREATE OR ALTER FUNCTION [dbo].[GetScoreByDate] 
(
	@datetime DATETIME
)
RETURNS BIGINT
AS
BEGIN	
	DECLARE @Score BIGINT

	SELECT @Score = ISNULL(SUM(Score), 0)
	FROM dbo.Posts
	WHERE ClosedDate > @datetime

	RETURN @Score
END
GO



CREATE OR ALTER FUNCTION [dbo].[GetScoreByDate2] 
(
	@datetime DATETIME
)
RETURNS BIGINT
WITH RETURNS NULL ON NULL INPUT 
AS
BEGIN	
	DECLARE @Score BIGINT

	SELECT @Score = ISNULL(SUM(Score), 0)
	FROM dbo.Posts
	WHERE ClosedDate > @datetime

	RETURN @Score
END
GO









ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 130;
GO


/*
	What?! How they differ so much in terms of performance?!
*/
SELECT TOP 10
			ParentId
		, ISNULL(dbo.GetScoreByDate(ClosedDate), 0)
	FROM Posts
GO

SELECT TOP 10
			ParentId
		, ISNULL(dbo.GetScoreByDate2(ClosedDate), 0)
	FROM Posts
GO

/* But I heard that 2019 brings some goodies! (TSQL_SCALAR_UDF_INLINING) */
ALTER DATABASE [StackOverflow] SET COMPATIBILITY_LEVEL = 150;
GO

SELECT TOP 10
			ParentId
		, ISNULL(dbo.GetScoreByDate(ClosedDate), 0)
	FROM Posts
GO

SELECT TOP 10
			ParentId
		, ISNULL(dbo.GetScoreByDate2(ClosedDate), 0)
	FROM Posts
GO