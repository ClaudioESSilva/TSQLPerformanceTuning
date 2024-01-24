/*
	CTE
		- You use it once, it call it once
		- You mentioned twice, it will be called...?

	https://claudioessilva.eu/2017/11/30/Using-Common-Table-Expression-CTE-Did-you-know.../
*/

USE StackOverflow
GO


/*
	TURN ON ACTUAL PLAN and STATISTICS

	SET STATISTICS TIME, IO ON
*/

/*
	Just a regular CTE caught in the wild
*/
;WITH TotalPostsAndViews AS
(
	SELECT OwnerUserId
			, COUNT(1) AS NumberPosts
			, SUM(ViewCount) AS SumViewCount
	  FROM dbo.Posts
	 WHERE PostTypeId = 1
	GROUP BY OwnerUserId
)
SELECT DisplayName
		, NumberPosts
		, SumViewCount
  FROM (
		SELECT TOP 10 
				  U.DisplayName
				, cte.NumberPosts
				, cte.SumViewCount
		  FROM dbo.Users AS U
			INNER JOIN TotalPostsAndViews AS cte
			ON U.Id = OwnerUserId
		ORDER BY cte.SumViewCount DESC, cte.NumberPosts DESC
		UNION ALL
		SELECT TOP 10 
				  U.DisplayName
				, cte.NumberPosts
				, cte.SumViewCount
		  FROM dbo.Users AS U
			INNER JOIN TotalPostsAndViews AS cte
			ON U.Id = OwnerUserId
		ORDER BY cte.SumViewCount, cte.NumberPosts
		) x
GO

/*
	What can we do different?

	Pre-aggregate the data and insert on a #tmp table and query it after
*/
DROP TABLE IF EXISTS #tmp
SELECT OwnerUserId
		, COUNT(1) AS NumberPosts
		, SUM(ViewCount) AS SumViewCount
  INTO #tmp
  FROM dbo.Posts
 WHERE PostTypeId = 1
GROUP BY OwnerUserId

SELECT DisplayName
		, NumberPosts
		, SumViewCount
  FROM (
		SELECT TOP 10 
				  U.DisplayName
				, cte.NumberPosts
				, cte.SumViewCount
		  FROM dbo.Users AS U
			INNER JOIN #tmp AS cte
			ON U.Id = OwnerUserId
		ORDER BY cte.SumViewCount DESC, cte.NumberPosts DESC
		UNION ALL
		SELECT TOP 10 
				  U.DisplayName
				, cte.NumberPosts
				, cte.SumViewCount
		  FROM dbo.Users AS U
			INNER JOIN #tmp AS cte
			ON U.Id = OwnerUserId
		ORDER BY cte.SumViewCount, cte.NumberPosts
		) x
GO






/*
	The easy way to proof
*/
WITH cte AS
(
	SELECT NEWID() AS Col1
)
SELECT Col1
  FROM cte
UNION ALL
SELECT Col1
  FROM cte
GO

/*
	Bottom line: 
		A CTE will run more than once if mentioned more than once
*/